defmodule OxideApi.Supervisor do
  @moduledoc """
  Supervision tree and lifecycle helpers for long-running Oxide clients.

  The supervisor starts a `Registry` and a `DynamicSupervisor`. Client
  processes are started dynamically and registered by caller-provided IDs, which
  makes it natural to keep one client per rack, project, silo, tenant, or any
  other application-level boundary.
  """

  use Supervisor

  alias OxideApi.{Client, ManagedClient}

  @default_registry __MODULE__.Registry
  @default_client_supervisor __MODULE__.ClientSupervisor

  @type client_id :: term()
  @type lifecycle_opts :: [
          registry: GenServer.server(),
          client_supervisor: GenServer.server()
        ]

  @doc """
  Starts the Oxide supervisor tree.

  Options:

    * `:name` - process name for this supervisor, defaults to `#{inspect(__MODULE__)}`
    * `:registry` - registry name, defaults to `#{inspect(@default_registry)}`
    * `:client_supervisor` - dynamic supervisor name, defaults to
      `#{inspect(@default_client_supervisor)}`
    * `:clients` - initial clients as `{id, opts}` pairs
    * `:cache` - cache child options, or `true` for the default cache
  """
  @spec start_link(keyword()) :: Supervisor.on_start()
  def start_link(opts \\ []) do
    {name, opts} = Keyword.pop(opts, :name, __MODULE__)
    Supervisor.start_link(__MODULE__, opts, name: name)
  end

  @doc false
  @spec child_spec(keyword()) :: Supervisor.child_spec()
  def child_spec(opts) do
    id = Keyword.get(opts, :name, __MODULE__)

    %{
      id: id,
      start: {__MODULE__, :start_link, [opts]},
      type: :supervisor
    }
  end

  @impl Supervisor
  def init(opts) do
    registry = Keyword.get(opts, :registry, @default_registry)
    client_supervisor = Keyword.get(opts, :client_supervisor, @default_client_supervisor)
    clients = Keyword.get(opts, :clients, [])
    cache = Keyword.get(opts, :cache, false)

    children =
      [
        {Registry, keys: :unique, name: registry},
        {DynamicSupervisor, strategy: :one_for_one, name: client_supervisor}
      ] ++ cache_specs(cache) ++ initial_client_specs(clients, registry)

    Supervisor.init(children, strategy: :rest_for_one)
  end

  @doc """
  Starts a dynamically supervised client registered under `id`.

  Client options are the same as `OxideApi.Client.new/1`. Lifecycle options
  `:registry` and `:client_supervisor` select a non-default supervisor tree.
  """
  @spec start_client(client_id(), keyword()) :: DynamicSupervisor.on_start_child()
  def start_client(id, opts \\ []) do
    {registry, opts} = Keyword.pop(opts, :registry, @default_registry)
    {client_supervisor, opts} = Keyword.pop(opts, :client_supervisor, @default_client_supervisor)

    DynamicSupervisor.start_child(
      client_supervisor,
      managed_client_spec(id, opts, registry)
    )
  catch
    :exit, {:noproc, _call} -> {:error, :not_started}
  end

  @doc """
  Starts a dynamically supervised client scoped to an Oxide project.

  The default registry ID is `{:project, project}`. Override it with `:id` when
  an application wants a different lookup key.
  """
  @spec start_project_client(String.t(), keyword()) :: DynamicSupervisor.on_start_child()
  def start_project_client(project, opts \\ []) when is_binary(project) do
    {id, opts} = Keyword.pop(opts, :id, {:project, project})

    id
    |> start_client(Keyword.put(opts, :scope, {:project, project}))
  end

  @doc """
  Starts a dynamically supervised client scoped to an Oxide silo.

  The default registry ID is `{:silo, silo}`. Override it with `:id` when an
  application wants a different lookup key.
  """
  @spec start_silo_client(String.t(), keyword()) :: DynamicSupervisor.on_start_child()
  def start_silo_client(silo, opts \\ []) when is_binary(silo) do
    {id, opts} = Keyword.pop(opts, :id, {:silo, silo})

    id
    |> start_client(Keyword.put(opts, :scope, {:silo, silo}))
  end

  @doc """
  Fetches a supervised client by ID.
  """
  @spec client(client_id(), lifecycle_opts()) :: {:ok, Client.t()} | {:error, :not_found}
  def client(id, opts \\ []) do
    with {:ok, pid} <- whereis(id, opts) do
      {:ok, ManagedClient.client(pid)}
    end
  catch
    :exit, {:noproc, _call} -> {:error, :not_found}
  end

  @doc """
  Fetches full lifecycle metadata for a supervised client by ID.
  """
  @spec info(client_id(), lifecycle_opts()) :: {:ok, ManagedClient.t()} | {:error, :not_found}
  def info(id, opts \\ []) do
    with {:ok, pid} <- whereis(id, opts) do
      {:ok, ManagedClient.info(pid)}
    end
  catch
    :exit, {:noproc, _call} -> {:error, :not_found}
  end

  @doc """
  Fetches the optional scope metadata for a supervised client by ID.
  """
  @spec scope(client_id(), lifecycle_opts()) :: {:ok, term()} | {:error, :not_found}
  def scope(id, opts \\ []) do
    with {:ok, pid} <- whereis(id, opts) do
      {:ok, ManagedClient.scope(pid)}
    end
  catch
    :exit, {:noproc, _call} -> {:error, :not_found}
  end

  @doc """
  Returns the PID for a supervised client by ID.
  """
  @spec whereis(client_id(), lifecycle_opts()) :: {:ok, pid()} | {:error, :not_found}
  def whereis(id, opts \\ []) do
    registry = Keyword.get(opts, :registry, @default_registry)

    case Registry.lookup(registry, id) do
      [{pid, _value}] -> {:ok, pid}
      [] -> {:error, :not_found}
    end
  catch
    :exit, {:noproc, _call} -> {:error, :not_found}
  end

  @doc """
  Stops a dynamically supervised client by ID.
  """
  @spec stop_client(client_id(), lifecycle_opts()) :: :ok | {:error, :not_found}
  def stop_client(id, opts \\ []) do
    client_supervisor = Keyword.get(opts, :client_supervisor, @default_client_supervisor)

    with {:ok, pid} <- whereis(id, opts) do
      case DynamicSupervisor.terminate_child(client_supervisor, pid) do
        :ok -> :ok
        {:error, :not_found} -> {:error, :not_found}
      end
    end
  catch
    :exit, {:noproc, _call} -> {:error, :not_found}
  end

  @doc """
  Returns the `:via` tuple used to register a client ID.
  """
  @spec via_tuple(client_id(), lifecycle_opts()) ::
          {:via, Registry, {GenServer.server(), client_id()}}
  def via_tuple(id, opts \\ []) do
    registry = Keyword.get(opts, :registry, @default_registry)
    {:via, Registry, {registry, id}}
  end

  defp initial_client_specs(clients, registry) do
    Enum.map(clients, fn
      {id, opts} when is_list(opts) ->
        managed_client_spec(id, opts, registry)

      opts when is_list(opts) ->
        id = Keyword.fetch!(opts, :id)
        managed_client_spec(id, opts, registry)
    end)
  end

  defp cache_specs(false), do: []
  defp cache_specs(true), do: [OxideApi.Cache]
  defp cache_specs(opts) when is_list(opts), do: [{OxideApi.Cache, opts}]

  defp managed_client_spec(id, opts, registry) do
    opts =
      opts
      |> Keyword.delete(:id)
      |> Keyword.put(:id, id)
      |> Keyword.put(:name, via_tuple(id, registry: registry))

    Supervisor.child_spec({ManagedClient, opts}, id: {ManagedClient, id})
  end
end
