defmodule OxideApi.Me do
  @moduledoc """
  Current-user endpoints.
  """

  alias OxideApi.Client

  @spec get(Client.t()) :: Client.result()
  def get(%Client{} = client), do: Client.get(client, "/v1/me")

  @spec groups(Client.t(), keyword()) :: Client.result()
  def groups(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/me/groups", params: params)
  end

  @spec list_ssh_keys(Client.t(), keyword()) :: Client.result()
  def list_ssh_keys(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/me/ssh-keys", params: params)
  end

  @spec create_ssh_key(Client.t(), map()) :: Client.result()
  def create_ssh_key(%Client{} = client, body) when is_map(body) do
    Client.post(client, "/v1/me/ssh-keys", body)
  end

  @spec get_ssh_key(Client.t(), String.t()) :: Client.result()
  def get_ssh_key(%Client{} = client, ssh_key) do
    Client.get(client, "/v1/me/ssh-keys/#{Client.path_segment(ssh_key)}")
  end

  @spec delete_ssh_key(Client.t(), String.t()) :: Client.result()
  def delete_ssh_key(%Client{} = client, ssh_key) do
    Client.delete(client, "/v1/me/ssh-keys/#{Client.path_segment(ssh_key)}")
  end

  @spec list_access_tokens(Client.t(), keyword()) :: Client.result()
  def list_access_tokens(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/me/access-tokens", params: params)
  end

  @spec delete_access_token(Client.t(), String.t()) :: Client.result()
  def delete_access_token(%Client{} = client, token_id) do
    Client.delete(client, "/v1/me/access-tokens/#{Client.path_segment(token_id)}")
  end
end
