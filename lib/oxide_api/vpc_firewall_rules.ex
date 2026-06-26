defmodule OxideApi.VpcFirewallRules do
  @moduledoc """
  VPC firewall rule endpoints.
  """

  alias OxideApi.Client

  @spec get(Client.t(), keyword()) :: Client.result()
  def get(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/vpc-firewall-rules", params: params)
  end

  @spec update(Client.t(), map(), keyword()) :: Client.result()
  def update(%Client{} = client, body, params \\ []) when is_map(body) do
    Client.put(client, "/v1/vpc-firewall-rules", body, params: params)
  end
end
