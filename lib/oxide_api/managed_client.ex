defmodule OxideApi.ManagedClient do
  @moduledoc """
  Long-running process that owns an `OxideApi.Client`.

  Use this when an application wants an Oxide client to participate in its OTP
  supervision tree. The process stores a built client and optional scope
  metadata, but HTTP requests still run in the caller process after fetching the
  client. That keeps concurrent API calls from being serialized through this
  GenServer.
  """

  use GenServer

  alias OxideApi.Client

  defstruct [:id, :scope, :client]

  @type id :: term()
  @type scope :: term()
  @type t :: %__MODULE__{
          id: id() | nil,
          scope: scope() | nil,
          client: Client.t()
        }

  @doc """
  Starts a managed client process.

  Pass either a prebuilt `:client` or the same options accepted by
  `OxideApi.Client.new/1`. `:id` and `:scope` are stored as lifecycle metadata;
  `:name` is used as the GenServer process name.
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) when is_list(opts) do
    {name, opts} = Keyword.pop(opts, :name)

    genserver_opts =
      if name do
        [name: name]
      else
        []
      end

    GenServer.start_link(__MODULE__, opts, genserver_opts)
  end

  @doc false
  @spec child_spec(keyword()) :: Supervisor.child_spec()
  def child_spec(opts) do
    id = Keyword.get(opts, :id, Keyword.get(opts, :name, __MODULE__))

    %{
      id: {__MODULE__, id},
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 5_000
    }
  end

  @impl GenServer
  def init(opts) do
    {id, opts} = Keyword.pop(opts, :id)
    {scope, opts} = Keyword.pop(opts, :scope)
    {client, opts} = Keyword.pop(opts, :client)

    case build_client(client, opts) do
      {:ok, %Client{} = client} ->
        {:ok, %__MODULE__{id: id, scope: scope, client: client}}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  @doc """
  Returns the owned `OxideApi.Client`.
  """
  @spec client(GenServer.server()) :: Client.t()
  def client(server), do: GenServer.call(server, :client)

  @doc """
  Returns lifecycle metadata for the managed client.
  """
  @spec info(GenServer.server()) :: t()
  def info(server), do: GenServer.call(server, :info)

  @doc """
  Returns the optional scope metadata.
  """
  @spec scope(GenServer.server()) :: scope() | nil
  def scope(server), do: GenServer.call(server, :scope)

  @doc """
  Makes a raw request with the owned client.
  """
  @spec request(GenServer.server(), atom(), String.t(), keyword()) :: Client.result()
  def request(server, method, path, opts \\ []) do
    server
    |> client()
    |> Client.request(method, path, opts)
  end

  @doc """
  Makes a raw request with the owned client and returns response metadata.
  """
  @spec request_with_meta(GenServer.server(), atom(), String.t(), keyword()) ::
          Client.response_result()
  def request_with_meta(server, method, path, opts \\ []) do
    server
    |> client()
    |> Client.request_with_meta(method, path, opts)
  end

  @impl GenServer
  def handle_call(:client, _from, %__MODULE__{client: client} = state) do
    {:reply, client, state}
  end

  def handle_call(:info, _from, %__MODULE__{} = state) do
    {:reply, state, state}
  end

  def handle_call(:scope, _from, %__MODULE__{scope: scope} = state) do
    {:reply, scope, state}
  end

  defp build_client(%Client{} = client, _opts), do: {:ok, client}
  defp build_client(nil, opts), do: Client.new(opts)
end
