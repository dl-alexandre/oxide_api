defmodule OxideApi.System.Timeseries do
  @moduledoc """
  System timeseries query endpoints.
  """

  alias OxideApi.Client

  @spec schemas(Client.t(), keyword()) :: Client.result()
  def schemas(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/system/timeseries/schemas", params: params)
  end

  @spec query(Client.t(), map()) :: Client.result()
  def query(%Client{} = client, body) when is_map(body) do
    Client.post(client, "/v1/system/timeseries/query", body)
  end
end
