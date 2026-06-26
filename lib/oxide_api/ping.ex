defmodule OxideApi.Ping do
  @moduledoc """
  API status endpoint.
  """

  alias OxideApi.Client

  @spec get(Client.t()) :: Client.result()
  def get(%Client{} = client), do: Client.get(client, "/v1/ping")
end
