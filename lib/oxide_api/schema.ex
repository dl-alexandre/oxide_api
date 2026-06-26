defmodule OxideApi.Schema do
  @moduledoc false

  @docs_api_url "https://docs.oxide.computer/api"
  @docs_intro_url "https://docs.oxide.computer/api/guides/introduction"
  @default_artifact_path "priv/oxide_api/endpoints.json"
  @default_openapi_path "priv/oxide_api/openapi/2026060800.0.0.json"
  @default_openapi_url "https://raw.githubusercontent.com/oxidecomputer/oxide.rs/v0.17.0%2B2026060800.0.0/oxide.json"
  @default_tags_url "https://api.github.com/repos/oxidecomputer/oxide.rs/tags?per_page=100"
  @http_methods ~w(delete get patch post put)
  @json_content_type "application/json"

  @openapi_candidate_urls [
    @default_openapi_url,
    "https://docs.oxide.computer/openapi.json",
    "https://docs.oxide.computer/api/openapi.json",
    "https://docs.oxide.computer/api.json",
    "https://docs.oxide.computer/api/spec.json",
    "https://docs.oxide.computer/api/schema.json",
    "https://docs.oxide.computer/api/latest/openapi.json",
    "https://docs.oxide.computer/api/2026060800.0.0/openapi.json"
  ]

  @type inventory :: %{
          required(:source) => String.t(),
          required(:source_type) => String.t(),
          required(:version) => String.t() | nil,
          required(:paths) => [String.t()],
          optional(:operations) => [map()]
        }

  @spec default_artifact_path() :: String.t()
  def default_artifact_path, do: @default_artifact_path

  @spec default_openapi_path() :: String.t()
  def default_openapi_path, do: @default_openapi_path

  @spec default_openapi_url() :: String.t()
  def default_openapi_url, do: @default_openapi_url

  @spec default_tags_url() :: String.t()
  def default_tags_url, do: @default_tags_url

  @spec fetch_inventory!(keyword()) :: inventory()
  def fetch_inventory!(opts \\ []) do
    schema_path = Keyword.get(opts, :schema_path, @default_openapi_path)
    schema_urls = Keyword.get(opts, :schema_urls, @openapi_candidate_urls)

    case load_openapi_schema(schema_path) do
      {:ok, schema} ->
        inventory_from_openapi(schema, schema_path, "vendored_openapi")

      :error ->
        case fetch_openapi_schema(schema_urls) do
          {:ok, schema, source} -> inventory_from_openapi(schema, source, "remote_openapi")
          :error -> fetch_docs_inventory!()
        end
    end
  end

  @spec latest_openapi!(keyword()) :: map()
  def latest_openapi!(opts \\ []) do
    tag = Keyword.get(opts, :tag) || latest_tag!(opts)
    %{api_version: api_version} = schema_tag_info!(tag)
    url = openapi_url_for_tag(tag)
    schema = url |> fetch_body!() |> decode_openapi!(url)
    schema_version = get_in(schema, ["info", "version"])

    if schema_version != api_version do
      raise "schema version mismatch for #{tag}: expected #{api_version}, found #{schema_version}"
    end

    %{
      tag: tag,
      api_version: api_version,
      version: schema_version,
      url: url,
      schema: schema,
      inventory: inventory_from_openapi(schema, url, "remote_openapi")
    }
  end

  @spec latest_tag!(keyword()) :: String.t()
  def latest_tag!(opts \\ []) do
    opts
    |> Keyword.get(:tags_url, @default_tags_url)
    |> fetch_tags!()
    |> Enum.map(&schema_tag_info/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.max_by(& &1.api_version_parts, fn -> raise "no Oxide schema tags found" end)
    |> Map.fetch!(:tag)
  end

  @spec openapi_url_for_tag(String.t()) :: String.t()
  def openapi_url_for_tag(tag) do
    encoded_tag = URI.encode(tag, &URI.char_unreserved?/1)
    "https://raw.githubusercontent.com/oxidecomputer/oxide.rs/#{encoded_tag}/oxide.json"
  end

  @spec refresh_openapi!(keyword()) :: String.t()
  def refresh_openapi!(opts \\ []) do
    url = Keyword.get(opts, :url, @default_openapi_url)
    path = Keyword.get(opts, :path, @default_openapi_path)

    schema =
      url
      |> fetch_body!()
      |> decode_openapi!(url)

    path
    |> Path.dirname()
    |> File.mkdir_p!()

    File.write!(path, Jason.encode!(schema, pretty: true) <> "\n")
    path
  end

  @spec write_openapi!(map(), String.t()) :: String.t()
  def write_openapi!(schema, path) when is_map(schema) do
    path
    |> Path.dirname()
    |> File.mkdir_p!()

    File.write!(path, Jason.encode!(schema, pretty: true) <> "\n")
    path
  end

  @spec fetch_docs_inventory!() :: inventory()
  def fetch_docs_inventory! do
    api_html = fetch_body!(@docs_api_url)
    intro_html = fetch_body!(@docs_intro_url)

    %{
      source: @docs_api_url,
      source_type: "docs_endpoint_inventory",
      version: extract_version(intro_html) || extract_version(api_html),
      paths: extract_paths(api_html),
      operations: []
    }
  end

  @spec extract_paths(String.t()) :: [String.t()]
  def extract_paths(contents) do
    ~r/["`]((?:\/device|\/login|\/v1|\/experimental\/v1)\/[^"`\\<\s]*)/
    |> Regex.scan(contents)
    |> Enum.map(fn [_match, path] -> normalize_path(path) end)
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
    |> Enum.sort()
  end

  @spec extract_version(String.t()) :: String.t() | nil
  def extract_version(contents) do
    case Regex.run(~r/current version is.*?([0-9]+\.[0-9]+\.[0-9]+)/s, contents) do
      [_, version] -> version
      _ -> nil
    end
  end

  @spec local_paths(String.t()) :: [String.t()]
  def local_paths(root \\ "lib") do
    root
    |> Path.join("**/*.ex")
    |> Path.wildcard()
    |> Enum.flat_map(&paths_in_file/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  @spec local_operations(String.t()) :: [map()]
  def local_operations(root \\ "lib") do
    root
    |> Path.join("**/*.ex")
    |> Path.wildcard()
    |> Enum.flat_map(&operations_in_file/1)
    |> unique_operations()
  end

  @spec coverage([String.t()], [String.t()]) :: map()
  def coverage(remote_paths, local_paths \\ local_paths()) do
    remote = MapSet.new(remote_paths)
    local = MapSet.new(local_paths)
    covered = MapSet.intersection(remote, local)
    missing = MapSet.difference(remote, local)
    extra = MapSet.difference(local, remote)

    %{
      total: MapSet.size(remote),
      covered: MapSet.size(covered),
      coverage_percent: coverage_percent(MapSet.size(covered), MapSet.size(remote)),
      missing: missing |> MapSet.to_list() |> Enum.sort(),
      extra: extra |> MapSet.to_list() |> Enum.sort()
    }
  end

  @spec operation_coverage([map()], [map()]) :: map()
  def operation_coverage(remote_operations, local_operations \\ local_operations()) do
    remote = MapSet.new(Enum.map(remote_operations, &operation_key/1))
    local = MapSet.new(Enum.map(local_operations, &operation_key/1))
    covered = MapSet.intersection(remote, local)
    missing = MapSet.difference(remote, local)
    extra = MapSet.difference(local, remote)

    %{
      total: MapSet.size(remote),
      covered: MapSet.size(covered),
      coverage_percent: coverage_percent(MapSet.size(covered), MapSet.size(remote)),
      missing: filter_operations(remote_operations, missing),
      extra: filter_operations(local_operations, extra)
    }
  end

  @spec paginated_operations(inventory() | [map()]) :: [map()]
  def paginated_operations(%{operations: operations}), do: paginated_operations(operations)
  def paginated_operations(%{"operations" => operations}), do: paginated_operations(operations)

  def paginated_operations(operations) when is_list(operations) do
    Enum.filter(operations, fn
      %{paginated: true} -> true
      %{"paginated" => true} -> true
      _operation -> false
    end)
  end

  @spec diff_inventories(inventory(), inventory()) :: map()
  def diff_inventories(current, latest) do
    current_paths = MapSet.new(paths(current))
    latest_paths = MapSet.new(paths(latest))
    current_operations = MapSet.new(Enum.map(operations(current), &operation_key/1))
    latest_operations = MapSet.new(Enum.map(operations(latest), &operation_key/1))

    %{
      paths: %{
        added:
          latest_paths |> MapSet.difference(current_paths) |> MapSet.to_list() |> Enum.sort(),
        removed:
          current_paths |> MapSet.difference(latest_paths) |> MapSet.to_list() |> Enum.sort()
      },
      operations: %{
        added:
          latest_operations
          |> MapSet.difference(current_operations)
          |> operation_keys_to_labels(),
        removed:
          current_operations
          |> MapSet.difference(latest_operations)
          |> operation_keys_to_labels()
      }
    }
  end

  @spec write_inventory!(inventory(), String.t()) :: :ok
  def write_inventory!(inventory, path \\ @default_artifact_path) do
    path
    |> Path.dirname()
    |> File.mkdir_p!()

    body =
      inventory
      |> Map.put(:generated_at, DateTime.utc_now() |> DateTime.to_iso8601())
      |> Jason.encode!(pretty: true)

    File.write!(path, body <> "\n")
  end

  defp load_openapi_schema(nil), do: :error

  defp load_openapi_schema(path) do
    with true <- File.exists?(path),
         {:ok, %{"openapi" => _} = schema} <- path |> File.read!() |> Jason.decode() do
      {:ok, schema}
    else
      _ -> :error
    end
  end

  defp fetch_openapi_schema(urls) do
    Enum.find_value(urls, :error, fn url ->
      case Req.get(url, retry: false, receive_timeout: 15_000, redirect_log_level: false) do
        {:ok, %Req.Response{status: 200, body: %{"openapi" => _} = schema}} ->
          {:ok, schema, url}

        {:ok, %Req.Response{status: 200, body: body}} when is_binary(body) ->
          decode_openapi(body, url)

        _ ->
          nil
      end
    end)
  end

  defp fetch_tags!(url) do
    case Req.get(url, retry: false, receive_timeout: 15_000, redirect_log_level: false) do
      {:ok, %Req.Response{status: 200, body: tags}} when is_list(tags) ->
        Enum.map(tags, & &1["name"])

      {:ok, %Req.Response{status: 200, body: body}} when is_binary(body) ->
        body
        |> Jason.decode!()
        |> Enum.map(& &1["name"])

      {:ok, %Req.Response{status: status}} ->
        raise "failed to fetch #{url}: HTTP #{status}"

      {:error, reason} ->
        raise "failed to fetch #{url}: #{inspect(reason)}"
    end
  end

  defp schema_tag_info!(tag) do
    schema_tag_info(tag) || raise "invalid Oxide schema tag #{inspect(tag)}"
  end

  defp schema_tag_info(tag) when is_binary(tag) do
    case Regex.named_captures(~r/^v(?<sdk_version>[^+]+)\+(?<api_version>\d+\.\d+\.\d+)$/, tag) do
      %{"sdk_version" => sdk_version, "api_version" => api_version} ->
        %{
          tag: tag,
          sdk_version: sdk_version,
          api_version: api_version,
          api_version_parts: version_parts(api_version)
        }

      nil ->
        nil
    end
  end

  defp schema_tag_info(_tag), do: nil

  defp version_parts(version) do
    version
    |> String.split(".")
    |> Enum.map(&String.to_integer/1)
  end

  defp decode_openapi(body, url) do
    case Jason.decode(body) do
      {:ok, %{"openapi" => _} = schema} -> {:ok, schema, url}
      _ -> nil
    end
  end

  defp decode_openapi!(body, source) do
    case Jason.decode(body) do
      {:ok, %{"openapi" => _} = schema} ->
        schema

      _ ->
        raise "failed to decode OpenAPI schema from #{source}"
    end
  end

  defp inventory_from_openapi(%{"info" => info, "paths" => paths} = schema, source, source_type)
       when is_map(paths) do
    %{
      source: source,
      source_type: source_type,
      version: info["version"],
      paths: paths |> Map.keys() |> Enum.map(&normalize_path/1) |> Enum.sort(),
      operations: operations_from_openapi_paths(paths, schema)
    }
  end

  defp fetch_body!(url) do
    case Req.get(url, retry: false, receive_timeout: 15_000, redirect_log_level: false) do
      {:ok, %Req.Response{status: 200, body: body}} when is_binary(body) ->
        body

      {:ok, %Req.Response{status: 200, body: body}} ->
        Jason.encode!(body)

      {:ok, %Req.Response{status: status}} ->
        raise "failed to fetch #{url}: HTTP #{status}"

      {:error, reason} ->
        raise "failed to fetch #{url}: #{inspect(reason)}"
    end
  end

  defp paths_in_file(path) do
    path
    |> File.read!()
    |> extract_local_paths()
  end

  defp operations_in_file(path) do
    path
    |> File.read!()
    |> extract_local_operations()
  end

  defp extract_local_paths(contents) do
    ~r/"((?:\/device|\/login|\/v1|\/experimental\/v1)[^"]*)"/
    |> Regex.scan(contents)
    |> Enum.map(fn [_match, path] ->
      ~r/#\{Client\.path_segment\(([^)]+)\)\}/
      |> Regex.replace(path, "{\\1}")
      |> normalize_path()
    end)
    |> Enum.reject(&(&1 == ""))
  end

  defp extract_local_operations(contents) do
    method_operations =
      ~r/Client\.(delete|get|patch|post|put)\(\s*client,\s*"((?:\/device|\/login|\/v1|\/experimental\/v1)[^"]*)"/s
      |> Regex.scan(contents)
      |> Enum.map(fn [_match, method, path] -> local_operation(method, path) end)

    raw_request_operations =
      ~r/Client\.request\(\s*client,\s*:(delete|get|patch|post|put),\s*"((?:\/device|\/login|\/v1|\/experimental\/v1)[^"]*)"/s
      |> Regex.scan(contents)
      |> Enum.map(fn [_match, method, path] -> local_operation(method, path) end)

    method_operations
    |> Kernel.++(raw_request_operations)
    |> Enum.reject(&(&1.path == ""))
    |> unique_operations()
  end

  defp local_operation(method, path) do
    %{
      method: method,
      path:
        ~r/#\{Client\.path_segment\(([^)]+)\)\}/
        |> Regex.replace(path, "{\\1}")
        |> normalize_path()
    }
  end

  defp operations_from_openapi_paths(paths, schema) do
    schemas = get_in(schema, ["components", "schemas"]) || %{}

    paths
    |> Enum.flat_map(fn {path, operations} ->
      operations
      |> Enum.filter(fn {method, _operation} -> method in @http_methods end)
      |> Enum.map(fn {method, operation} ->
        response_schema = operation_response_schema(operation)
        resolved_schema = resolve_schema(response_schema, schemas)

        %{
          method: method,
          path: normalize_path(path),
          operation_id: operation["operationId"],
          summary: operation["summary"],
          parameters: operation_parameters(operation),
          request_content_type: operation_request_content_type(operation),
          request_schema: operation_request_schema(operation),
          request_body_required: operation_request_body_required?(operation),
          paginated: paginated_schema?(resolved_schema),
          response_status: operation_response_status(operation),
          response_content_type: operation_response_content_type(operation),
          response_schema: schema_name(response_schema),
          item_schema: item_schema_name(resolved_schema)
        }
      end)
    end)
    |> unique_operations()
  end

  defp operation_response_schema(operation) do
    operation
    |> operation_response_body()
    |> case do
      nil -> nil
      {_status, _content_type, schema} -> schema
    end
  end

  defp operation_response_status(operation) do
    operation
    |> Map.get("responses", %{})
    |> success_response_statuses()
    |> case do
      [{status, _response} | _responses] -> status
      [] -> nil
    end
  end

  defp operation_response_content_type(operation) do
    operation
    |> operation_response_body()
    |> case do
      nil -> nil
      {_status, content_type, _schema} -> content_type
    end
  end

  defp operation_response_body(operation) do
    responses = Map.get(operation, "responses", %{})

    responses
    |> success_response_statuses()
    |> Enum.find_value(fn {status, response} ->
      response_body(status, response)
    end)
  end

  defp operation_request_schema(operation) do
    operation
    |> operation_request_body()
    |> case do
      nil -> nil
      {_content_type, schema} -> schema_name(schema)
    end
  end

  defp operation_request_content_type(operation) do
    operation
    |> operation_request_body()
    |> case do
      nil -> nil
      {content_type, _schema} -> content_type
    end
  end

  defp operation_request_body_required?(operation) do
    get_in(operation, ["requestBody", "required"]) == true
  end

  defp operation_request_body(operation) do
    content = get_in(operation, ["requestBody", "content"]) || %{}

    preferred_content_type =
      Enum.find(
        [@json_content_type, "application/x-www-form-urlencoded"],
        &Map.has_key?(content, &1)
      )

    content_type =
      preferred_content_type ||
        content |> Map.keys() |> Enum.sort() |> List.first()

    if content_type do
      schema = get_in(content, [content_type, "schema"])
      {content_type, schema}
    end
  end

  defp response_body(status, response) do
    content = Map.get(response, "content", %{})

    content_type =
      if Map.has_key?(content, @json_content_type) do
        @json_content_type
      else
        content |> Map.keys() |> Enum.sort() |> List.first()
      end

    if content_type do
      {status, content_type, get_in(content, [content_type, "schema"])}
    end
  end

  defp success_status?(status) when is_binary(status) do
    String.match?(status, ~r/^2\d\d$/)
  end

  defp success_status?(_status), do: false

  defp success_response_statuses(responses) do
    responses
    |> Enum.filter(fn {status, _response} -> success_status?(status) end)
    |> Enum.sort_by(fn {status, _response} -> status end)
  end

  defp operation_parameters(operation) do
    operation
    |> Map.get("parameters", [])
    |> Enum.map(fn parameter ->
      schema = parameter["schema"] || %{}

      %{
        name: parameter["name"],
        in: parameter["in"],
        required: parameter["required"] == true,
        schema: schema_name(schema),
        type: schema_type(schema),
        format: schema["format"]
      }
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)
      |> Map.new()
    end)
  end

  defp resolve_schema(%{"$ref" => ref}, schemas) do
    schemas
    |> Map.get(ref_name(ref), %{})
    |> resolve_schema(schemas)
  end

  defp resolve_schema(%{"allOf" => [schema | _schemas]}, schemas),
    do: resolve_schema(schema, schemas)

  defp resolve_schema(schema, _schemas) when is_map(schema), do: schema
  defp resolve_schema(_schema, _schemas), do: %{}

  defp paginated_schema?(%{"type" => "object", "properties" => properties})
       when is_map(properties) do
    items = properties["items"]
    next_page = properties["next_page"]

    is_map(items) and items["type"] == "array" and is_map(next_page) and
      next_page["type"] == "string"
  end

  defp paginated_schema?(_schema), do: false

  defp schema_name(%{"$ref" => ref}), do: ref_name(ref)
  defp schema_name(_schema), do: nil

  defp schema_type(%{"type" => type}), do: type
  defp schema_type(%{"$ref" => _ref}), do: nil
  defp schema_type(%{"allOf" => [schema | _schemas]}), do: schema_type(schema)
  defp schema_type(_schema), do: nil

  defp item_schema_name(%{"properties" => %{"items" => %{"items" => item_schema}}}) do
    schema_name(item_schema) || item_schema["type"]
  end

  defp item_schema_name(_schema), do: nil

  defp ref_name(ref) do
    ref
    |> String.split("/")
    |> List.last()
  end

  defp unique_operations(operations) do
    operations
    |> Enum.uniq_by(&operation_key/1)
    |> Enum.sort_by(&operation_key/1)
  end

  defp operation_key(%{method: method, path: path}), do: {method, path}
  defp operation_key(%{"method" => method, "path" => path}), do: {method, path}

  defp operation_keys_to_labels(keys) do
    keys
    |> MapSet.to_list()
    |> Enum.map(fn {method, path} -> "#{String.upcase(method)} #{path}" end)
    |> Enum.sort()
  end

  defp paths(%{paths: paths}), do: paths
  defp paths(%{"paths" => paths}), do: paths

  defp operations(%{operations: operations}), do: operations
  defp operations(%{"operations" => operations}), do: operations

  defp filter_operations(operations, keys) do
    operations
    |> Enum.filter(&(operation_key(&1) in keys))
    |> unique_operations()
  end

  defp normalize_path(path) do
    path
    |> String.replace("\\/", "/")
    |> String.trim_trailing("\\")
    |> String.split("?")
    |> List.first()
    |> String.trim()
  end

  defp coverage_percent(_covered, 0), do: 100.0

  defp coverage_percent(covered, total) do
    Float.round(covered / total * 100, 2)
  end
end
