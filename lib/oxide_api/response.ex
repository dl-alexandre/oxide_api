defmodule OxideApi.Response do
  @moduledoc """
  Response metadata returned by `OxideApi.Client.request_with_meta/4`.
  """

  defstruct [
    :status,
    :headers,
    :body
  ]

  @type header :: {String.t(), String.t()}

  @type t :: %__MODULE__{
          status: non_neg_integer(),
          headers: [header()],
          body: term()
        }

  @doc """
  Returns all values for a response header.
  """
  @spec get_headers(t(), String.t()) :: [String.t()]
  def get_headers(%__MODULE__{headers: headers}, name) do
    normalized = String.downcase(name)

    headers
    |> Enum.filter(fn {key, _value} -> String.downcase(key) == normalized end)
    |> Enum.map(fn {_key, value} -> value end)
  end

  @doc """
  Returns the first value for a response header.
  """
  @spec get_header(t(), String.t(), String.t() | nil) :: String.t() | nil
  def get_header(%__MODULE__{} = response, name, default \\ nil) do
    response
    |> get_headers(name)
    |> List.first(default)
  end
end
