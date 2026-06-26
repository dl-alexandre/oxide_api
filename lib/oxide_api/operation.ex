defmodule OxideApi.Operation do
  @moduledoc """
  Runtime helpers for schema-derived operation metadata.

  The metadata comes from `priv/oxide_api/endpoints.json`, which is generated
  by `mix oxide_api.schema --write`.
  """

  alias OxideApi.Client

  @type parameter :: %{
          required(:name) => String.t(),
          required(:in) => String.t(),
          required(:required) => boolean(),
          optional(:schema) => String.t(),
          optional(:type) => String.t(),
          optional(:format) => String.t()
        }

  @type t :: %{
          method: String.t(),
          path: String.t(),
          operation_id: String.t() | nil,
          summary: String.t() | nil,
          parameters: [parameter()],
          request_content_type: String.t() | nil,
          request_schema: String.t() | nil,
          request_body_required: boolean(),
          paginated: boolean(),
          response_status: String.t() | nil,
          response_content_type: String.t() | nil,
          response_schema: String.t() | nil,
          item_schema: String.t() | nil
        }

  @doc """
  Returns every operation from the generated endpoint inventory.
  """
  @spec all() :: [t()]
  def all do
    inventory()
    |> Map.get("operations", [])
    |> Enum.map(&normalize/1)
  end

  @doc """
  Returns the generated metadata for one OpenAPI `operationId`.
  """
  @spec fetch(String.t() | atom()) :: {:ok, t()} | :error
  def fetch(operation_id) do
    id = to_string(operation_id)

    case Enum.find(all(), &(&1.operation_id == id)) do
      nil -> :error
      operation -> {:ok, operation}
    end
  end

  @doc """
  Returns the generated metadata for one OpenAPI `operationId`, or raises.
  """
  @spec fetch!(String.t() | atom()) :: t()
  def fetch!(operation_id) do
    case fetch(operation_id) do
      {:ok, operation} ->
        operation

      :error ->
        raise ArgumentError, "unknown Oxide API operation #{inspect(operation_id)}"
    end
  end

  @doc """
  Returns operations whose response schema is a paginated results page.
  """
  @spec paginated() :: [t()]
  def paginated do
    all()
    |> Enum.filter(& &1.paginated)
  end

  @doc """
  Returns the generated request body schema name for an operation.
  """
  @spec request_schema(t() | String.t() | atom()) :: String.t() | nil
  def request_schema(operation_or_id), do: operation!(operation_or_id).request_schema

  @doc """
  Returns the generated response body schema name for an operation.
  """
  @spec response_schema(t() | String.t() | atom()) :: String.t() | nil
  def response_schema(operation_or_id), do: operation!(operation_or_id).response_schema

  @doc """
  Returns the generated success response status for an operation.
  """
  @spec response_status(t() | String.t() | atom()) :: String.t() | nil
  def response_status(operation_or_id), do: operation!(operation_or_id).response_status

  @doc """
  Returns generated parameter metadata for an operation.
  """
  @spec parameters(t() | String.t() | atom()) :: [parameter()]
  def parameters(operation_or_id), do: operation!(operation_or_id).parameters

  @doc """
  Returns generated query parameter metadata for an operation.
  """
  @spec query_parameters(t() | String.t() | atom()) :: [parameter()]
  def query_parameters(operation_or_id), do: parameters_by_location(operation_or_id, "query")

  @doc """
  Returns generated path parameter metadata for an operation.
  """
  @spec path_parameters(t() | String.t() | atom()) :: [parameter()]
  def path_parameters(operation_or_id), do: parameters_by_location(operation_or_id, "path")

  @doc """
  Renders a schema path by replacing `{name}` placeholders.
  """
  @spec render_path(String.t(), keyword() | map()) :: String.t()
  def render_path(path, path_params \\ []) when is_binary(path) do
    Regex.replace(~r/{([^}]+)}/, path, fn _match, key ->
      path_params
      |> fetch_path_param!(key)
      |> Client.path_segment()
    end)
  end

  @doc """
  Streams items for a paginated operation ID or raw path.

  When passing an operation ID with path placeholders, provide replacements in
  `:path_params`. Query params can be passed either as top-level keyword options
  or under `:params`.
  """
  @spec stream(Client.t(), String.t() | atom(), keyword() | map()) :: Enumerable.t()
  def stream(client, operation_or_path, opts \\ [])

  def stream(%Client{} = client, "/" <> _ = path, opts) do
    {path_params, params} = split_stream_opts(opts)
    Client.stream_items(client, render_path(path, path_params), params)
  end

  def stream(%Client{} = client, operation_id, opts) do
    operation = fetch!(operation_id)
    ensure_paginated_get!(operation, operation_id)

    {path_params, params} = split_stream_opts(opts)
    Client.stream_items(client, render_path(operation.path, path_params), params)
  end

  @doc """
  Fetches every item for a paginated operation ID or raw path.
  """
  @spec fetch_all(Client.t(), String.t() | atom(), keyword() | map()) ::
          {:ok, [term()]} | {:error, term()}
  def fetch_all(client, operation_or_path, opts \\ [])

  def fetch_all(%Client{} = client, "/" <> _ = path, opts) do
    {path_params, params} = split_stream_opts(opts)
    Client.fetch_all_items(client, render_path(path, path_params), params)
  end

  def fetch_all(%Client{} = client, operation_id, opts) do
    operation = fetch!(operation_id)
    ensure_paginated_get!(operation, operation_id)

    {path_params, params} = split_stream_opts(opts)
    Client.fetch_all_items(client, render_path(operation.path, path_params), params)
  end

  defp inventory do
    inventory_path()
    |> File.read!()
    |> Jason.decode!()
  end

  defp inventory_path do
    case :code.priv_dir(:oxide_api) do
      path when is_list(path) ->
        Path.join([to_string(path), "oxide_api", "endpoints.json"])

      {:error, _reason} ->
        "priv/oxide_api/endpoints.json"
    end
  end

  defp normalize(operation) do
    %{
      method: operation["method"],
      path: operation["path"],
      operation_id: operation["operation_id"],
      summary: operation["summary"],
      parameters: normalize_parameters(operation["parameters"] || []),
      request_content_type: operation["request_content_type"],
      request_schema: operation["request_schema"],
      request_body_required: operation["request_body_required"] == true,
      paginated: operation["paginated"] == true,
      response_status: operation["response_status"],
      response_content_type: operation["response_content_type"],
      response_schema: operation["response_schema"],
      item_schema: operation["item_schema"]
    }
  end

  defp normalize_parameters(parameters) do
    Enum.map(parameters, fn parameter ->
      %{
        name: parameter["name"],
        in: parameter["in"],
        required: parameter["required"] == true
      }
      |> maybe_put(:schema, parameter["schema"])
      |> maybe_put(:type, parameter["type"])
      |> maybe_put(:format, parameter["format"])
    end)
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp operation!(%{method: _method, path: _path} = operation), do: operation
  defp operation!(operation_id), do: fetch!(operation_id)

  defp parameters_by_location(operation_or_id, location) do
    operation_or_id
    |> parameters()
    |> Enum.filter(&(&1.in == location))
  end

  defp fetch_path_param!(path_params, key) do
    cond do
      is_map(path_params) and Map.has_key?(path_params, key) ->
        Map.fetch!(path_params, key)

      is_map(path_params) and Map.has_key?(path_params, String.to_atom(key)) ->
        Map.fetch!(path_params, String.to_atom(key))

      is_list(path_params) ->
        fetch_list_path_param!(path_params, key)

      true ->
        raise_missing_path_param!(key)
    end
  end

  defp fetch_list_path_param!(path_params, key) do
    case Keyword.fetch(path_params, String.to_atom(key)) do
      {:ok, value} ->
        value

      :error ->
        case List.keyfind(path_params, key, 0) do
          {_key, value} -> value
          nil -> raise_missing_path_param!(key)
        end
    end
  end

  defp raise_missing_path_param!(key) do
    raise ArgumentError, "missing path param #{inspect(key)}"
  end

  defp split_stream_opts(opts) when is_map(opts), do: {[], opts}

  defp split_stream_opts(opts) when is_list(opts) do
    {path_params, opts} = Keyword.pop(opts, :path_params, [])

    case Keyword.pop(opts, :params) do
      {nil, params} -> {path_params, params}
      {params, _opts} -> {path_params, params}
    end
  end

  defp ensure_paginated_get!(%{method: "get", paginated: true}, _operation_id), do: :ok

  defp ensure_paginated_get!(operation, operation_id) do
    raise ArgumentError,
          "operation #{inspect(operation_id)} is not a paginated GET " <>
            "(#{String.upcase(operation.method)} #{operation.path})"
  end
end
