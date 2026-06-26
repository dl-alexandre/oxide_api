defmodule OxideApi.SubnetPools do
  @moduledoc """
  Subnet pool endpoints visible to the current silo.
  """

  alias OxideApi.Client

  @spec list(Client.t(), keyword()) :: Client.result()
  def list(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/subnet-pools", params: params)
  end

  @spec get(Client.t(), String.t(), keyword()) :: Client.result()
  def get(%Client{} = client, pool, params \\ []) do
    Client.get(client, "/v1/subnet-pools/#{Client.path_segment(pool)}", params: params)
  end
end
