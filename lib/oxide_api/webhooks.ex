defmodule OxideApi.Webhooks do
  @moduledoc """
  Webhook receiver and secret endpoints.
  """

  alias OxideApi.Client

  @spec list_receivers(Client.t(), keyword()) :: Client.result()
  def list_receivers(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/webhook-receivers", params: params)
  end

  @spec create_receiver(Client.t(), map()) :: Client.result()
  def create_receiver(%Client{} = client, body) when is_map(body) do
    Client.post(client, "/v1/webhook-receivers", body)
  end

  @spec get_receiver(Client.t(), String.t()) :: Client.result()
  def get_receiver(%Client{} = client, receiver) do
    Client.get(client, "/v1/webhook-receivers/#{Client.path_segment(receiver)}")
  end

  @spec update_receiver(Client.t(), String.t(), map()) :: Client.result()
  def update_receiver(%Client{} = client, receiver, body) when is_map(body) do
    Client.put(client, "/v1/webhook-receivers/#{Client.path_segment(receiver)}", body)
  end

  @spec delete_receiver(Client.t(), String.t()) :: Client.result()
  def delete_receiver(%Client{} = client, receiver) do
    Client.delete(client, "/v1/webhook-receivers/#{Client.path_segment(receiver)}")
  end

  @spec list_secrets(Client.t(), keyword()) :: Client.result()
  def list_secrets(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/webhook-secrets", params: params)
  end

  @spec create_secret(Client.t(), map()) :: Client.result()
  def create_secret(%Client{} = client, body) when is_map(body) do
    Client.post(client, "/v1/webhook-secrets", body)
  end

  @spec delete_secret(Client.t(), String.t()) :: Client.result()
  def delete_secret(%Client{} = client, secret_id) do
    Client.delete(client, "/v1/webhook-secrets/#{Client.path_segment(secret_id)}")
  end
end
