defmodule OxideApi.Timeseries do
  @moduledoc """
  Timeseries query endpoints.
  """

  alias OxideApi.Client

  @spec query(Client.t(), map()) :: Client.result()
  def query(%Client{} = client, body) when is_map(body) do
    Client.post(client, "/v1/timeseries/query", body)
  end
end
