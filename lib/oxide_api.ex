defmodule OxideApi do
  @moduledoc """
  Elixir client for the Oxide control plane API.

  Start by creating a client:

      {:ok, client} =
        OxideApi.new(
          host: "https://my-oxide-rack.com",
          token: "oxide-abc123"
        )

  The client sends the Oxide `api-version` header automatically and uses device
  tokens as bearer tokens. Request bodies and responses are plain Elixir maps
  decoded from the JSON API. Use `request_with_meta/4` when you also need HTTP
  status and response headers.
  """

  alias OxideApi.{Client, Operation}

  @doc """
  The Oxide API schema version this library targets.
  """
  @spec api_version() :: String.t()
  defdelegate api_version, to: Client

  @doc """
  Builds a new client.

  Options can be passed directly, configured through `Application` env, or read
  from `OXIDE_HOST` and `OXIDE_TOKEN`.
  """
  @spec new(keyword()) :: {:ok, Client.t()} | {:error, OxideApi.Error.t()}
  defdelegate new(opts \\ []), to: Client

  @doc """
  Builds a client without bearer-token authentication.

  Use this for device authorization endpoints before an access token exists.
  """
  @spec new_unauthenticated(keyword()) :: {:ok, Client.t()} | {:error, OxideApi.Error.t()}
  defdelegate new_unauthenticated(opts \\ []), to: Client

  @doc """
  Builds a new client, raising when required configuration is missing.
  """
  @spec new!(keyword()) :: Client.t()
  defdelegate new!(opts \\ []), to: Client

  @doc """
  Makes a raw request against the Oxide API.
  """
  @spec request(Client.t(), atom(), String.t(), keyword()) ::
          {:ok, term()} | {:error, OxideApi.Error.t() | {:transport_error, term()}}
  defdelegate request(client, method, path, opts \\ []), to: Client

  @doc """
  Makes a raw request and returns response metadata.
  """
  @spec request_with_meta(Client.t(), atom(), String.t(), keyword()) ::
          Client.response_result()
  defdelegate request_with_meta(client, method, path, opts \\ []), to: Client

  @doc """
  Lazily streams items from a paginated list endpoint.
  """
  @spec stream_items(Client.t(), String.t(), keyword() | map()) :: Enumerable.t()
  defdelegate stream_items(client, path, params \\ []), to: Client

  @doc """
  Lazily streams items from a schema-derived paginated operation or raw path.

  Operation IDs can be passed as atoms or strings:

      OxideApi.stream(client, :project_list, limit: 100)

  For operation paths with placeholders, pass `:path_params`.
  """
  @spec stream(Client.t(), String.t() | atom(), keyword() | map()) :: Enumerable.t()
  defdelegate stream(client, operation_or_path, opts \\ []), to: Operation

  @doc """
  Fetches all items from a paginated list endpoint.
  """
  @spec fetch_all_items(Client.t(), String.t(), keyword() | map()) ::
          {:ok, [term()]} | {:error, term()}
  defdelegate fetch_all_items(client, path, params \\ []), to: Client

  @doc """
  Fetches all items from a schema-derived paginated operation or raw path.
  """
  @spec fetch_all(Client.t(), String.t() | atom(), keyword() | map()) ::
          {:ok, [term()]} | {:error, term()}
  defdelegate fetch_all(client, operation_or_path, opts \\ []), to: Operation

  @doc """
  Runs an OxQL timeseries query.

  Pass `project: "name"` for the project-scoped endpoint. Without `:project`,
  the fleet/system scoped endpoint is used.
  """
  @spec query_oxql(Client.t(), String.t(), keyword()) :: Client.result()
  defdelegate query_oxql(client, query, opts \\ []), to: OxideApi.Oxql, as: :query

  @doc """
  Returns every schema operation known to the generated endpoint inventory.
  """
  @spec operations() :: [Operation.t()]
  defdelegate operations, to: Operation, as: :all

  @doc """
  Returns schema operations whose response body is paginated.
  """
  @spec paginated_operations() :: [Operation.t()]
  defdelegate paginated_operations, to: Operation, as: :paginated

  @doc "Lists projects visible to the authenticated user."
  @spec list_projects(Client.t(), keyword()) :: Client.result()
  defdelegate list_projects(client, params \\ []), to: OxideApi.Projects, as: :list

  @doc "Streams projects visible to the authenticated user."
  @spec stream_projects(Client.t(), keyword()) :: Enumerable.t()
  defdelegate stream_projects(client, params \\ []), to: OxideApi.Projects, as: :stream

  @doc "Creates a project."
  @spec create_project(Client.t(), map()) :: Client.result()
  defdelegate create_project(client, body), to: OxideApi.Projects, as: :create

  @doc "Fetches a project by name or ID."
  @spec get_project(Client.t(), String.t()) :: Client.result()
  defdelegate get_project(client, project), to: OxideApi.Projects, as: :get

  @doc "Updates a project by name or ID."
  @spec update_project(Client.t(), String.t(), map()) :: Client.result()
  defdelegate update_project(client, project, body), to: OxideApi.Projects, as: :update

  @doc "Deletes a project by name or ID."
  @spec delete_project(Client.t(), String.t()) :: Client.result()
  defdelegate delete_project(client, project), to: OxideApi.Projects, as: :delete

  @doc "Lists disks. Pass `project: \"name\"` for project-scoped calls."
  @spec list_disks(Client.t(), keyword()) :: Client.result()
  defdelegate list_disks(client, params \\ []), to: OxideApi.Disks, as: :list

  @doc "Streams disks. Pass `project: \"name\"` for project-scoped calls."
  @spec stream_disks(Client.t(), keyword()) :: Enumerable.t()
  defdelegate stream_disks(client, params \\ []), to: OxideApi.Disks, as: :stream

  @doc "Creates a disk. Pass `project: \"name\"` for project-scoped calls."
  @spec create_disk(Client.t(), map(), keyword()) :: Client.result()
  defdelegate create_disk(client, body, params \\ []), to: OxideApi.Disks, as: :create

  @doc "Lists instances. Pass `project: \"name\"` for project-scoped calls."
  @spec list_instances(Client.t(), keyword()) :: Client.result()
  defdelegate list_instances(client, params \\ []), to: OxideApi.Instances, as: :list

  @doc "Streams instances. Pass `project: \"name\"` for project-scoped calls."
  @spec stream_instances(Client.t(), keyword()) :: Enumerable.t()
  defdelegate stream_instances(client, params \\ []), to: OxideApi.Instances, as: :stream

  @doc "Creates an instance. Pass `project: \"name\"` for project-scoped calls."
  @spec create_instance(Client.t(), map(), keyword()) :: Client.result()
  defdelegate create_instance(client, body, params \\ []), to: OxideApi.Instances, as: :create

  @doc "Lists images. Pass `project: \"name\"` for project-scoped calls."
  @spec list_images(Client.t(), keyword()) :: Client.result()
  defdelegate list_images(client, params \\ []), to: OxideApi.Images, as: :list
end
