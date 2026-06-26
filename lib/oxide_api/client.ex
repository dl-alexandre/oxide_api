defmodule OxideApi.Client do
  @moduledoc """
  Low-level HTTP client for the Oxide API.
  """

  alias OxideApi.{Config, Error, Response}

  @api_version "2026060800.0.0"

  defstruct [
    :host,
    :token,
    :api_version,
    :user_agent,
    :req_options
  ]

  @type t :: %__MODULE__{
          host: String.t(),
          token: String.t() | nil,
          api_version: String.t(),
          user_agent: String.t(),
          req_options: keyword()
        }

  @type result :: {:ok, term()} | {:error, Error.t() | {:transport_error, term()}}
  @type response_result :: {:ok, Response.t()} | {:error, Error.t() | {:transport_error, term()}}

  @config_keys [
    :api_version,
    :config_dir,
    :connect_options,
    :host,
    :pool_timeout,
    :receive_timeout,
    :req_options,
    :retry,
    :token,
    :user_agent
  ]

  @doc "The Oxide API schema version this client targets."
  @spec api_version() :: String.t()
  def api_version, do: @api_version

  @doc """
  Builds a client from explicit options, application env, or Oxide env vars.
  """
  @spec new(keyword()) :: {:ok, t()} | {:error, Error.t()}
  def new(opts \\ []) do
    config = Config.load(opts)

    with :ok <- require_string(:host, config.host),
         :ok <- require_string(:token, config.token) do
      {:ok,
       %__MODULE__{
         host: normalize_host(config.host),
         token: config.token,
         api_version: config.api_version,
         user_agent: config.user_agent,
         req_options: config.req_options
       }}
    end
  end

  @doc """
  Builds a client without bearer-token authentication.

  This is intended for unauthenticated flows such as OAuth device
  authorization, where the token is the result of the API call.
  """
  @spec new_unauthenticated(keyword()) :: {:ok, t()} | {:error, Error.t()}
  def new_unauthenticated(opts \\ []) do
    config = Config.load(opts)

    with :ok <- require_string(:host, config.host) do
      {:ok,
       %__MODULE__{
         host: normalize_host(config.host),
         token: nil,
         api_version: config.api_version,
         user_agent: config.user_agent,
         req_options: config.req_options
       }}
    end
  end

  @doc """
  Builds a client or raises `OxideApi.Error` when configuration is missing.
  """
  @spec new!(keyword()) :: t()
  def new!(opts \\ []) do
    case new(opts) do
      {:ok, client} -> client
      {:error, error} -> raise error
    end
  end

  @doc "Makes a `GET` request."
  @spec get(t(), String.t(), keyword()) :: result()
  def get(client, path, opts \\ []), do: request(client, :get, path, opts)

  @doc "Makes a `POST` request."
  @spec post(t(), String.t(), map(), keyword()) :: result()
  def post(client, path, body, opts \\ []),
    do: request(client, :post, path, Keyword.put(opts, :json, body))

  @doc "Makes a `PUT` request."
  @spec put(t(), String.t(), map(), keyword()) :: result()
  def put(client, path, body, opts \\ []),
    do: request(client, :put, path, Keyword.put(opts, :json, body))

  @doc "Makes a `PATCH` request."
  @spec patch(t(), String.t(), map(), keyword()) :: result()
  def patch(client, path, body, opts \\ []),
    do: request(client, :patch, path, Keyword.put(opts, :json, body))

  @doc "Makes a `DELETE` request."
  @spec delete(t(), String.t(), keyword()) :: result()
  def delete(client, path, opts \\ []), do: request(client, :delete, path, opts)

  @doc """
  Makes a raw request against the Oxide API.

  Supported request options:

  * `:params` - query parameters
  * `:json` - JSON request body
  * `:form` - form-encoded request body
  * `:body` - raw request body
  * `:headers` - extra request headers
  * `:req_options` - per-request options merged into `Req`
  """
  @spec request(t(), atom(), String.t(), keyword()) :: result()
  def request(%__MODULE__{} = client, method, path, opts \\ []) do
    case request_with_meta(client, method, path, opts) do
      {:ok, %Response{body: body}} -> {:ok, body}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Makes a raw request and returns status, headers, and body.
  """
  @spec request_with_meta(t(), atom(), String.t(), keyword()) :: response_result()
  def request_with_meta(%__MODULE__{} = client, method, path, opts \\ []) do
    {request_opts, opts} = Keyword.split(opts, [:params, :json, :form, :body])
    {extra_headers, opts} = Keyword.pop(opts, :headers, [])
    {req_options, _opts} = Keyword.pop(opts, :req_options, [])

    req =
      Req.new(
        base_url: client.host,
        headers: headers(client, extra_headers)
      )
      |> Req.merge(client.req_options)
      |> Req.merge(req_options)

    req
    |> Req.request([method: method, url: path] ++ request_opts)
    |> normalize_with_meta()
  end

  @doc """
  Streams every item from a paginated Oxide list endpoint.

  The stream fetches pages lazily and raises `OxideApi.Error` if a later page
  fails. Use `fetch_all_items/3` when you need an explicit `{:ok, items}` /
  `{:error, reason}` result instead.
  """
  @spec stream_items(t(), String.t(), keyword() | map()) :: Enumerable.t()
  def stream_items(%__MODULE__{} = client, path, params \\ []) do
    Stream.resource(
      fn -> {:fetch, params} end,
      fn
        :halt ->
          {:halt, :halt}

        {:fetch, page_params} ->
          case get(client, path, params: page_params) do
            {:ok, page} ->
              {items(page), next_page_state(page, page_params)}

            {:error, %Error{} = error} ->
              raise error

            {:error, {:transport_error, reason}} ->
              raise RuntimeError, "Oxide API transport error: #{inspect(reason)}"
          end
      end,
      fn _state -> :ok end
    )
  end

  @doc """
  Fetches all items from a paginated Oxide list endpoint.
  """
  @spec fetch_all_items(t(), String.t(), keyword() | map()) :: {:ok, [term()]} | {:error, term()}
  def fetch_all_items(%__MODULE__{} = client, path, params \\ []) do
    fetch_all_items(client, path, params, [])
  end

  @doc false
  @spec split_resource_opts(keyword()) :: {keyword(), keyword()}
  def split_resource_opts(opts), do: Keyword.split(opts, @config_keys)

  @doc false
  @spec path_segment(term()) :: String.t()
  def path_segment(value) do
    value
    |> to_string()
    |> URI.encode(&URI.char_unreserved?/1)
  end

  defp headers(%__MODULE__{} = client, extra_headers) do
    [
      {"accept", "application/json"},
      {"api-version", client.api_version},
      {"user-agent", client.user_agent}
    ]
    |> maybe_put_authorization(client.token)
    |> Kernel.++(extra_headers)
  end

  defp maybe_put_authorization(headers, token) when is_binary(token) do
    [{"authorization", "Bearer #{token}"} | headers]
  end

  defp maybe_put_authorization(headers, _token), do: headers

  defp normalize_with_meta({:ok, %Req.Response{status: status} = response})
       when status in 200..299 do
    {:ok, to_response(response)}
  end

  defp normalize_with_meta({:ok, %Req.Response{status: status, body: body} = response}) do
    {:error, Error.from_http(status, normalize_body(status, body), headers(response))}
  end

  defp normalize_with_meta({:error, reason}), do: {:error, {:transport_error, reason}}

  defp to_response(%Req.Response{status: status, body: body} = response) do
    %Response{
      status: status,
      headers: headers(response),
      body: normalize_body(status, body)
    }
  end

  defp headers(%Req.Response{} = response) do
    response
    |> Req.Response.to_map()
    |> Map.fetch!(:headers)
  end

  defp normalize_body(status, _body) when status in [204, 205], do: nil
  defp normalize_body(_status, body), do: body

  defp fetch_all_items(client, path, params, acc) do
    case get(client, path, params: params) do
      {:ok, page} ->
        next_acc = acc ++ items(page)

        case next_page_state(page, params) do
          :halt -> {:ok, next_acc}
          {:fetch, next_params} -> fetch_all_items(client, path, next_params, next_acc)
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp items(%{"items" => items}) when is_list(items), do: items
  defp items(%{items: items}) when is_list(items), do: items
  defp items(_page), do: []

  defp next_page_state(page, params) do
    case next_page_token(page) do
      nil -> :halt
      "" -> :halt
      token -> {:fetch, put_page_token(params, token)}
    end
  end

  defp next_page_token(%{"next_page" => token}), do: token
  defp next_page_token(%{"next_page_token" => token}), do: token
  defp next_page_token(%{next_page: token}), do: token
  defp next_page_token(%{next_page_token: token}), do: token
  defp next_page_token(_page), do: nil

  defp put_page_token(params, token) when is_map(params) do
    Map.put(params, :page_token, token)
  end

  defp put_page_token(params, token) when is_list(params) do
    params
    |> List.keydelete(:page_token, 0)
    |> List.keydelete("page_token", 0)
    |> Keyword.put(:page_token, token)
  end

  defp require_string(name, value) when is_binary(value) do
    if String.trim(value) == "" do
      {:error, Error.config("missing required :#{name} option")}
    else
      :ok
    end
  end

  defp require_string(name, _value),
    do: {:error, Error.config("missing required :#{name} option")}

  defp normalize_host(host), do: String.trim_trailing(host, "/")
end
