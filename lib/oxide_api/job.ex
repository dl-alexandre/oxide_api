defmodule OxideApi.Job do
  @moduledoc """
  Helpers for running Oxide operations from background jobs.

  The helpers keep Oban arguments JSON-safe by storing client IDs and resource
  IDs instead of `%OxideApi.Client{}` structs. Workers resolve clients from
  `OxideApi.Supervisor` at execution time.
  """

  alias OxideApi.{Error, Operation, Wait, Workflows}

  @type args :: map() | keyword()
  @type oban_result :: :ok | {:error, term()} | {:cancel, term()} | {:snooze, non_neg_integer()}

  @doc """
  Builds an Oban changeset for provisioning an instance with a boot disk.
  """
  @spec provision_instance(args(), keyword()) :: term()
  def provision_instance(args, opts \\ []) do
    args = args |> normalize_args() |> put_instance_name()
    new(OxideApi.Oban.ProvisionInstanceWorker, args, opts)
  end

  @doc """
  Builds an Oban changeset for waiting until an instance reaches a state.
  """
  @spec wait_for_instance(args(), keyword()) :: term()
  def wait_for_instance(args, opts \\ []) do
    new(OxideApi.Oban.WaitForInstanceWorker, normalize_args(args), opts)
  end

  @doc """
  Builds an Oban changeset for a generated operation-ID request.
  """
  @spec request_operation(args(), keyword()) :: term()
  def request_operation(args, opts \\ []) do
    new(OxideApi.Oban.RequestOperationWorker, normalize_args(args), opts)
  end

  @doc """
  Builds many Oban changesets from argument maps.
  """
  @spec bulk((args(), keyword() -> term()), [args()], keyword()) :: [term()]
  def bulk(builder, args_list, opts \\ []) when is_function(builder, 2) and is_list(args_list) do
    Enum.map(args_list, &builder.(&1, opts))
  end

  @doc """
  Builds provision-instance jobs for many instances.
  """
  @spec provision_instances(String.t(), String.t(), [args()], keyword()) :: [term()]
  def provision_instances(client_id, project, instances, opts \\ [])
      when is_binary(client_id) and is_binary(project) and is_list(instances) do
    {job_opts, shared_args} = Keyword.pop(opts, :job_opts, [])
    shared_args = normalize_args(Map.new(shared_args))

    Enum.map(instances, fn instance_args ->
      args =
        shared_args
        |> Map.merge(normalize_args(instance_args))
        |> Map.put("client_id", client_id)
        |> Map.put("project", project)

      provision_instance(args, job_opts)
    end)
  end

  @doc """
  Builds wait-for-instance jobs for many instances.
  """
  @spec wait_for_instances(String.t(), String.t(), [String.t()], String.t(), keyword()) :: [
          term()
        ]
  def wait_for_instances(client_id, project, instances, state, opts \\ [])
      when is_binary(client_id) and is_binary(project) and is_list(instances) and is_binary(state) do
    {job_opts, wait_opts} = Keyword.pop(opts, :job_opts, [])
    wait_opts = normalize_args(Map.new(wait_opts))

    Enum.map(instances, fn instance ->
      %{
        "client_id" => client_id,
        "project" => project,
        "instance" => instance,
        "state" => state
      }
      |> Map.merge(wait_opts)
      |> wait_for_instance(job_opts)
    end)
  end

  @doc """
  Builds generated operation-ID jobs for many operations.
  """
  @spec request_operations(String.t(), [args()], keyword()) :: [term()]
  def request_operations(client_id, operations, opts \\ [])
      when is_binary(client_id) and is_list(operations) do
    {job_opts, shared_args} = Keyword.pop(opts, :job_opts, [])
    shared_args = shared_args |> Map.new() |> normalize_args() |> Map.put("client_id", client_id)

    Enum.map(operations, fn operation_args ->
      operation_args
      |> normalize_args()
      |> Map.merge(shared_args, fn _key, operation_value, _shared_value -> operation_value end)
      |> request_operation(job_opts)
    end)
  end

  @doc """
  Builds an Oban changeset from a worker and JSON-safe arguments.
  """
  @spec new(module(), args(), keyword()) :: term()
  def new(worker, args, opts \\ []) when is_atom(worker) do
    if function_exported?(worker, :new, 2) do
      worker.new(normalize_args(args), opts)
    else
      {:error, :oban_not_loaded}
    end
  end

  @doc """
  Performs the provision-instance job.
  """
  @spec perform_provision_instance(args()) :: oban_result()
  def perform_provision_instance(args) do
    args = normalize_args(args)

    result =
      with {:ok, client} <- fetch_client(args),
           {:ok, project} <- fetch_required(args, "project"),
           {:ok, instance} <- fetch_required(args, "instance"),
           {:ok, disk} <- fetch_required(args, "disk"),
           {:ok, instance_name} <- instance_name(instance),
           {:ok, _created} <- Workflows.create_instance_with_disk(client, project, instance, disk) do
        maybe_wait_for_instance(client, project, instance_name, args)
      end

    to_oban_result(result)
  end

  @doc """
  Performs the wait-for-instance job.
  """
  @spec perform_wait_for_instance(args()) :: oban_result()
  def perform_wait_for_instance(args) do
    args = normalize_args(args)

    result =
      with {:ok, client} <- fetch_client(args),
           {:ok, instance} <- fetch_required(args, "instance"),
           {:ok, state} <- fetch_required(args, "state") do
        opts =
          args
          |> wait_opts()
          |> Keyword.merge(query_opts(args))

        Wait.instance_state(client, instance, state, opts)
      end

    to_oban_result(result)
  end

  @doc """
  Performs a generated operation-ID request.
  """
  @spec perform_request_operation(args()) :: oban_result()
  def perform_request_operation(args) do
    args = normalize_args(args)

    result =
      with {:ok, client} <- fetch_client(args),
           {:ok, operation_id} <- fetch_required(args, "operation_id") do
        Operation.request(client, operation_id,
          params: Map.get(args, "params", %{}),
          path_params: Map.get(args, "path_params", %{}),
          request_body: Map.get(args, "request_body")
        )
      end

    to_oban_result(result)
  end

  @doc """
  Converts a standard Oxide result tuple into an Oban worker result.
  """
  @spec to_oban_result({:ok, term()} | {:error, term()}) :: oban_result()
  def to_oban_result({:ok, _value}), do: :ok

  def to_oban_result({:error, %Error{} = error}) do
    cond do
      Error.not_found?(error) or error.error_code == "configuration_error" ->
        {:cancel, Exception.message(error)}

      Error.rate_limited?(error) ->
        {:snooze, 30}

      Error.retryable?(error) ->
        {:error, error}

      true ->
        {:cancel, Exception.message(error)}
    end
  end

  def to_oban_result({:error, {:transport_error, reason}}), do: {:error, reason}
  def to_oban_result({:error, reason}), do: {:error, reason}

  @doc """
  Normalizes job args to JSON-safe string-keyed maps.
  """
  @spec normalize_args(args()) :: map()
  def normalize_args(args) when is_list(args), do: args |> Map.new() |> normalize_args()

  def normalize_args(%{} = args) do
    Map.new(args, fn {key, value} -> {to_string(key), normalize_value(value)} end)
  end

  defp normalize_value(%{} = value), do: normalize_args(value)
  defp normalize_value(value) when is_list(value), do: Enum.map(value, &normalize_value/1)
  defp normalize_value(value) when is_atom(value), do: Atom.to_string(value)
  defp normalize_value(value), do: value

  defp fetch_client(args) do
    with {:ok, client_id} <- fetch_required(args, "client_id") do
      registry = Application.get_env(:oxide_api, :job_registry, OxideApi.Supervisor.Registry)

      case OxideApi.Supervisor.client(client_id, registry: registry) do
        {:ok, client} ->
          {:ok, client}

        {:error, :not_found} ->
          {:error, Error.config("supervised client not found: #{client_id}")}
      end
    end
  end

  defp maybe_wait_for_instance(client, project, instance_name, args) do
    case Map.get(args, "wait_until") do
      nil ->
        {:ok, :created}

      desired_state ->
        opts =
          args
          |> wait_opts()
          |> Keyword.put(:project, project)

        Wait.instance_state(client, instance_name, desired_state, opts)
    end
  end

  defp wait_opts(args) do
    []
    |> put_if_present(:interval, args, "interval")
    |> put_if_present(:timeout, args, "timeout")
  end

  defp query_opts(args) do
    []
    |> put_if_present(:project, args, "project")
  end

  defp put_if_present(opts, key, args, arg_key) do
    case Map.fetch(args, arg_key) do
      {:ok, value} -> Keyword.put(opts, key, value)
      :error -> opts
    end
  end

  defp put_instance_name(%{"instance" => instance} = args) when is_map(instance) do
    case instance_name(instance) do
      {:ok, name} -> Map.put_new(args, "name", name)
      {:error, _reason} -> args
    end
  end

  defp put_instance_name(args), do: args

  defp instance_name(%{} = instance) do
    case Map.get(instance, "name") || Map.get(instance, :name) do
      name when is_binary(name) and name != "" -> {:ok, name}
      _missing -> {:error, Error.config("missing required instance name")}
    end
  end

  defp fetch_required(args, key) do
    case Map.fetch(args, key) do
      {:ok, value} when value not in [nil, ""] -> {:ok, value}
      _missing -> {:error, Error.config("missing required #{key} job arg")}
    end
  end
end
