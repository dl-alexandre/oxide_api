defmodule OxideApi.System.Scim do
  @moduledoc """
  System SCIM token endpoints.
  """

  alias OxideApi.Client

  @spec tokens(Client.t(), keyword()) :: Client.result()
  def tokens(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/system/scim/tokens", params: params)
  end

  @spec create_token(Client.t(), map()) :: Client.result()
  def create_token(%Client{} = client, body) when is_map(body) do
    Client.post(client, "/v1/system/scim/tokens", body)
  end

  @spec get_token(Client.t(), String.t()) :: Client.result()
  def get_token(%Client{} = client, token_id) do
    Client.get(client, "/v1/system/scim/tokens/#{Client.path_segment(token_id)}")
  end

  @spec delete_token(Client.t(), String.t()) :: Client.result()
  def delete_token(%Client{} = client, token_id) do
    Client.delete(client, "/v1/system/scim/tokens/#{Client.path_segment(token_id)}")
  end
end
