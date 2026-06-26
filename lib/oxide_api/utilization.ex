defmodule OxideApi.Utilization do
  @moduledoc """
  Silo/project utilization endpoint.
  """

  alias OxideApi.Client

  @spec get(Client.t(), keyword()) :: Client.result()
  def get(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/utilization", params: params)
  end
end
