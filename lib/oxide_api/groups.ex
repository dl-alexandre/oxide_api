defmodule OxideApi.Groups do
  @moduledoc """
  Group endpoints.
  """

  alias OxideApi.Client

  @spec list(Client.t(), keyword()) :: Client.result()
  def list(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/groups", params: params)
  end

  @spec get(Client.t(), String.t()) :: Client.result()
  def get(%Client{} = client, group_id) do
    Client.get(client, "/v1/groups/#{Client.path_segment(group_id)}")
  end
end
