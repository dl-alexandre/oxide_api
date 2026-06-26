defmodule OxideApi.System.SiloQuotas do
  @moduledoc """
  System silo quota endpoint.
  """

  alias OxideApi.Client

  @spec get(Client.t()) :: Client.result()
  def get(%Client{} = client), do: Client.get(client, "/v1/system/silo-quotas")

  @spec update(Client.t(), map()) :: Client.result()
  def update(%Client{} = client, body) when is_map(body) do
    Client.put(client, "/v1/system/silo-quotas", body)
  end
end
