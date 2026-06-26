defmodule OxideApi.InternetGatewayIpAddresses do
  @moduledoc """
  Internet gateway IP address endpoints.
  """

  alias OxideApi.Client

  @spec list(Client.t(), keyword()) :: Client.result()
  def list(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/internet-gateway-ip-addresses", params: params)
  end

  @spec create(Client.t(), map(), keyword()) :: Client.result()
  def create(%Client{} = client, body, params \\ []) when is_map(body) do
    Client.post(client, "/v1/internet-gateway-ip-addresses", body, params: params)
  end

  @spec get(Client.t(), String.t(), keyword()) :: Client.result()
  def get(%Client{} = client, address, params \\ []) do
    Client.get(client, "/v1/internet-gateway-ip-addresses/#{Client.path_segment(address)}",
      params: params
    )
  end

  @spec delete(Client.t(), String.t(), keyword()) :: Client.result()
  def delete(%Client{} = client, address, params \\ []) do
    Client.delete(client, "/v1/internet-gateway-ip-addresses/#{Client.path_segment(address)}",
      params: params
    )
  end
end
