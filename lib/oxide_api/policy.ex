defmodule OxideApi.Policy do
  @moduledoc """
  Silo policy endpoints.
  """

  alias OxideApi.Client

  @spec get(Client.t()) :: Client.result()
  def get(%Client{} = client), do: Client.get(client, "/v1/policy")

  @spec update(Client.t(), map()) :: Client.result()
  def update(%Client{} = client, body) when is_map(body) do
    Client.put(client, "/v1/policy", body)
  end
end
