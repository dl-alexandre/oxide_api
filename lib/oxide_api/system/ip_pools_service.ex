defmodule OxideApi.System.IpPoolsService do
  @moduledoc """
  Service IP pool endpoints.
  """

  alias OxideApi.Client

  @spec get(Client.t()) :: Client.result()
  def get(%Client{} = client), do: Client.get(client, "/v1/system/ip-pools-service")

  @spec ranges(Client.t(), keyword()) :: Client.result()
  def ranges(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/system/ip-pools-service/ranges", params: params)
  end

  @spec add_range(Client.t(), map()) :: Client.result()
  def add_range(%Client{} = client, body) when is_map(body) do
    Client.post(client, "/v1/system/ip-pools-service/ranges/add", body)
  end

  @spec remove_range(Client.t(), map()) :: Client.result()
  def remove_range(%Client{} = client, body) when is_map(body) do
    Client.post(client, "/v1/system/ip-pools-service/ranges/remove", body)
  end
end
