defmodule OxideApi.VpcSubnets do
  @moduledoc """
  VPC subnet endpoints.
  """

  alias OxideApi.Client

  @spec list(Client.t(), keyword()) :: Client.result()
  def list(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/vpc-subnets", params: params)
  end

  @spec create(Client.t(), map(), keyword()) :: Client.result()
  def create(%Client{} = client, body, params \\ []) when is_map(body) do
    Client.post(client, "/v1/vpc-subnets", body, params: params)
  end

  @spec get(Client.t(), String.t(), keyword()) :: Client.result()
  def get(%Client{} = client, subnet, params \\ []) do
    Client.get(client, "/v1/vpc-subnets/#{Client.path_segment(subnet)}", params: params)
  end

  @spec update(Client.t(), String.t(), map(), keyword()) :: Client.result()
  def update(%Client{} = client, subnet, body, params \\ []) when is_map(body) do
    Client.put(client, "/v1/vpc-subnets/#{Client.path_segment(subnet)}", body, params: params)
  end

  @spec delete(Client.t(), String.t(), keyword()) :: Client.result()
  def delete(%Client{} = client, subnet, params \\ []) do
    Client.delete(client, "/v1/vpc-subnets/#{Client.path_segment(subnet)}", params: params)
  end

  @spec network_interfaces(Client.t(), String.t(), keyword()) :: Client.result()
  def network_interfaces(%Client{} = client, subnet, params \\ []) do
    Client.get(client, "/v1/vpc-subnets/#{Client.path_segment(subnet)}/network-interfaces",
      params: params
    )
  end
end
