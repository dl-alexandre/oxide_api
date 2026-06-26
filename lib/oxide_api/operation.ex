defmodule OxideApi.Operation do
  @moduledoc """
  Runtime helpers for schema-derived operation metadata.

  The metadata comes from `priv/oxide_api/endpoints.json`, which is generated
  by `mix oxide_api.schema --write`.
  """

  alias OxideApi.Client

  @type t :: %{
          method: String.t(),
          path: String.t(),
          operation_id: String.t() | nil,
          summary: String.t() | nil,
          paginated: boolean(),
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
      paginated: operation["paginated"] == true,
      response_schema: operation["response_schema"],
      item_schema: operation["item_schema"]
    }
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
