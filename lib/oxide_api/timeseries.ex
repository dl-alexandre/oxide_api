defmodule OxideApi.Timeseries do
  @moduledoc """
  Timeseries query endpoints.
  """

  alias OxideApi.Client

  @spec query(Client.t(), map(), keyword()) :: Client.result()
  def query(%Client{} = client, body, params \\ []) when is_map(body) do
    Client.post(client, "/v1/timeseries/query", body, params: params)
  end
end
