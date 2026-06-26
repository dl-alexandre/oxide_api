defmodule OxideApi.Error do
  @moduledoc """
  Structured error returned by the Oxide API client.
  """

  defexception [:message, :status, :error_code, :request_id, :details, :headers]

  @type t :: %__MODULE__{
          message: String.t(),
          status: non_neg_integer() | nil,
          error_code: String.t() | nil,
          request_id: String.t() | nil,
          details: term(),
          headers: [{String.t(), String.t()}]
        }

  @spec config(String.t()) :: t()
  def config(message) do
    %__MODULE__{
      message: message,
      status: nil,
      error_code: "configuration_error",
      request_id: nil,
      details: nil,
      headers: []
    }
  end

  @impl Exception
  def message(%__MODULE__{status: nil, error_code: "configuration_error"} = error) do
    "Oxide API configuration error: #{error.message}"
  end

  def message(%__MODULE__{} = error) do
    [
      "Oxide API request failed: #{error.message}",
      status_part(error),
      error_code_part(error),
      request_id_part(error)
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" ")
  end

  @spec from_http(non_neg_integer(), term(), [{String.t(), String.t()}]) :: t()
  def from_http(status, body, headers \\ [])

  def from_http(status, %{"message" => message} = body, headers) do
    %__MODULE__{
      message: message,
      status: status,
      error_code: body["error_code"],
      request_id: body["request_id"] || header(headers, "x-request-id"),
      details: body,
      headers: headers
    }
  end

  def from_http(status, body, headers) do
    %__MODULE__{
      message: reason_for(status),
      status: status,
      error_code: nil,
      request_id: header(headers, "x-request-id"),
      details: body,
      headers: headers
    }
  end

  @doc """
  Returns the request ID attached to an Oxide API error, when present.
  """
  @spec request_id(t()) :: String.t() | nil
  def request_id(%__MODULE__{request_id: request_id}), do: request_id

  @doc """
  Returns true for 404/not-found API errors.
  """
  @spec not_found?(t()) :: boolean()
  def not_found?(%__MODULE__{status: 404}), do: true
  def not_found?(%__MODULE__{error_code: "not_found"}), do: true
  def not_found?(%__MODULE__{}), do: false

  @doc """
  Returns true when retrying the request may reasonably succeed.
  """
  @spec retryable?(t()) :: boolean()
  def retryable?(%__MODULE__{status: status}) when status in [408, 425, 429], do: true
  def retryable?(%__MODULE__{status: status}) when status in 500..599, do: true
  def retryable?(%__MODULE__{}), do: false

  @doc """
  Returns true for rate-limit responses.
  """
  @spec rate_limited?(t()) :: boolean()
  def rate_limited?(%__MODULE__{status: 429}), do: true
  def rate_limited?(%__MODULE__{error_code: "rate_limited"}), do: true
  def rate_limited?(%__MODULE__{}), do: false

  @doc """
  Returns true for 5xx server-side failures.
  """
  @spec server_error?(t()) :: boolean()
  def server_error?(%__MODULE__{status: status}) when status in 500..599, do: true
  def server_error?(%__MODULE__{}), do: false

  @doc """
  Returns true when the error has the given HTTP status.
  """
  @spec status?(t(), non_neg_integer()) :: boolean()
  def status?(%__MODULE__{status: status}, status), do: true
  def status?(%__MODULE__{}, _status), do: false

  @doc """
  Returns compact metadata suitable for structured logs.
  """
  @spec to_log_metadata(t()) :: keyword()
  def to_log_metadata(%__MODULE__{} = error) do
    [
      oxide_status: error.status,
      oxide_error_code: error.error_code,
      oxide_request_id: error.request_id,
      oxide_retryable: retryable?(error)
    ]
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
  end

  defp status_part(%__MODULE__{status: nil}), do: nil
  defp status_part(%__MODULE__{status: status}), do: "(status: #{status})"

  defp error_code_part(%__MODULE__{error_code: nil}), do: nil
  defp error_code_part(%__MODULE__{error_code: error_code}), do: "(error_code: #{error_code})"

  defp request_id_part(%__MODULE__{request_id: nil}), do: nil
  defp request_id_part(%__MODULE__{request_id: request_id}), do: "(request_id: #{request_id})"

  defp header(headers, name) do
    Enum.find_value(headers, fn {header_name, value} ->
      if String.downcase(to_string(header_name)) == name do
        value
      end
    end)
  end

  defp reason_for(400), do: "bad request"
  defp reason_for(408), do: "request timeout"
  defp reason_for(401), do: "unauthorized"
  defp reason_for(403), do: "forbidden"
  defp reason_for(404), do: "not found"
  defp reason_for(409), do: "conflict"
  defp reason_for(422), do: "unprocessable entity"
  defp reason_for(429), do: "rate limited"
  defp reason_for(status) when status in 500..599, do: "server error"
  defp reason_for(_status), do: "Oxide API request failed"
end
