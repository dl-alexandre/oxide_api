defmodule OxideApi.InternetGatewayIpPools do
  @moduledoc """
  Internet gateway IP pool endpoints.
  """

  alias OxideApi.Client

  @spec list(Client.t(), keyword()) :: Client.result()
  def list(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/internet-gateway-ip-pools", params: params)
  end

  @spec create(Client.t(), map(), keyword()) :: Client.result()
  def create(%Client{} = client, body, params \\ []) when is_map(body) do
    Client.post(client, "/v1/internet-gateway-ip-pools", body, params: params)
  end

  @spec get(Client.t(), String.t(), keyword()) :: Client.result()
  def get(%Client{} = client, pool, params \\ []) do
    Client.get(client, "/v1/internet-gateway-ip-pools/#{Client.path_segment(pool)}",
      params: params
    )
  end

  @spec delete(Client.t(), String.t(), keyword()) :: Client.result()
  def delete(%Client{} = client, pool, params \\ []) do
    Client.delete(client, "/v1/internet-gateway-ip-pools/#{Client.path_segment(pool)}",
      params: params
    )
  end
end
