defmodule OxideApi.Login do
  @moduledoc """
  Login endpoints.
  """

  alias OxideApi.Client

  @type form_body :: map() | keyword()

  @spec device_auth(Client.t(), form_body()) :: Client.result()
  def device_auth(%Client{} = client, body) when is_map(body) do
    Client.request(client, :post, "/device/auth", form: body)
  end

  def device_auth(%Client{} = client, body) when is_list(body) do
    Client.request(client, :post, "/device/auth", form: body)
  end

  @spec device_confirm(Client.t(), form_body()) :: Client.result()
  def device_confirm(%Client{} = client, body) when is_map(body) do
    Client.request(client, :post, "/device/confirm", form: body)
  end

  def device_confirm(%Client{} = client, body) when is_list(body) do
    Client.request(client, :post, "/device/confirm", form: body)
  end

  @spec device_token(Client.t(), form_body()) :: Client.result()
  def device_token(%Client{} = client, body) when is_map(body) do
    Client.request(client, :post, "/device/token", form: body)
  end

  def device_token(%Client{} = client, body) when is_list(body) do
    Client.request(client, :post, "/device/token", form: body)
  end

  @spec local(Client.t(), String.t(), map()) :: Client.result()
  def local(%Client{} = client, silo_name, body) when is_map(body) do
    Client.post(client, "/v1/login/#{Client.path_segment(silo_name)}/local", body)
  end

  @spec saml(Client.t(), String.t(), String.t(), binary()) :: Client.result()
  def saml(%Client{} = client, silo_name, provider_name, body) when is_binary(body) do
    Client.request(
      client,
      :post,
      "/login/#{Client.path_segment(silo_name)}/saml/#{Client.path_segment(provider_name)}",
      body: body,
      headers: [{"content-type", "application/octet-stream"}]
    )
  end

  @spec logout(Client.t()) :: Client.result()
  def logout(%Client{} = client) do
    Client.request(client, :post, "/v1/logout")
  end
end
