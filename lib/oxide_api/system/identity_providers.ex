defmodule OxideApi.System.IdentityProviders do
  @moduledoc """
  System identity provider endpoints.
  """

  alias OxideApi.Client

  @spec list(Client.t(), keyword()) :: Client.result()
  def list(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/system/identity-providers", params: params)
  end

  @spec saml(Client.t(), keyword()) :: Client.result()
  def saml(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/system/identity-providers/saml", params: params)
  end

  @spec create_saml(Client.t(), map()) :: Client.result()
  def create_saml(%Client{} = client, body) when is_map(body) do
    Client.post(client, "/v1/system/identity-providers/saml", body)
  end

  @spec get_saml(Client.t(), String.t()) :: Client.result()
  def get_saml(%Client{} = client, provider) do
    Client.get(client, "/v1/system/identity-providers/saml/#{Client.path_segment(provider)}")
  end

  @spec update_saml(Client.t(), String.t(), map()) :: Client.result()
  def update_saml(%Client{} = client, provider, body) when is_map(body) do
    Client.put(
      client,
      "/v1/system/identity-providers/saml/#{Client.path_segment(provider)}",
      body
    )
  end

  @spec delete_saml(Client.t(), String.t()) :: Client.result()
  def delete_saml(%Client{} = client, provider) do
    Client.delete(client, "/v1/system/identity-providers/saml/#{Client.path_segment(provider)}")
  end

  @spec local_users(Client.t(), keyword()) :: Client.result()
  def local_users(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/system/identity-providers/local/users", params: params)
  end

  @spec create_local_user(Client.t(), map()) :: Client.result()
  def create_local_user(%Client{} = client, body) when is_map(body) do
    Client.post(client, "/v1/system/identity-providers/local/users", body)
  end

  @spec get_local_user(Client.t(), String.t()) :: Client.result()
  def get_local_user(%Client{} = client, user_id) do
    Client.get(
      client,
      "/v1/system/identity-providers/local/users/#{Client.path_segment(user_id)}"
    )
  end

  @spec delete_local_user(Client.t(), String.t()) :: Client.result()
  def delete_local_user(%Client{} = client, user_id) do
    Client.delete(
      client,
      "/v1/system/identity-providers/local/users/#{Client.path_segment(user_id)}"
    )
  end

  @spec set_local_user_password(Client.t(), String.t(), map()) :: Client.result()
  def set_local_user_password(%Client{} = client, user_id, body) when is_map(body) do
    Client.post(
      client,
      "/v1/system/identity-providers/local/users/#{Client.path_segment(user_id)}/set-password",
      body
    )
  end
end
