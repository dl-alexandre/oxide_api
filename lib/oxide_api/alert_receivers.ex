defmodule OxideApi.AlertReceivers do
  @moduledoc """
  Alert receiver endpoints.
  """

  alias OxideApi.Client

  @spec list(Client.t(), keyword()) :: Client.result()
  def list(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/alert-receivers", params: params)
  end

  @spec create(Client.t(), map()) :: Client.result()
  def create(%Client{} = client, body) when is_map(body) do
    Client.post(client, "/v1/alert-receivers", body)
  end

  @spec get(Client.t(), String.t()) :: Client.result()
  def get(%Client{} = client, receiver) do
    Client.get(client, "/v1/alert-receivers/#{Client.path_segment(receiver)}")
  end

  @spec update(Client.t(), String.t(), map()) :: Client.result()
  def update(%Client{} = client, receiver, body) when is_map(body) do
    Client.put(client, "/v1/alert-receivers/#{Client.path_segment(receiver)}", body)
  end

  @spec delete(Client.t(), String.t()) :: Client.result()
  def delete(%Client{} = client, receiver) do
    Client.delete(client, "/v1/alert-receivers/#{Client.path_segment(receiver)}")
  end

  @spec deliveries(Client.t(), String.t(), keyword()) :: Client.result()
  def deliveries(%Client{} = client, receiver, params \\ []) do
    Client.get(client, "/v1/alert-receivers/#{Client.path_segment(receiver)}/deliveries",
      params: params
    )
  end

  @spec probe(Client.t(), String.t(), map()) :: Client.result()
  def probe(%Client{} = client, receiver, body \\ %{}) when is_map(body) do
    Client.post(client, "/v1/alert-receivers/#{Client.path_segment(receiver)}/probe", body)
  end

  @spec subscriptions(Client.t(), String.t(), keyword()) :: Client.result()
  def subscriptions(%Client{} = client, receiver, params \\ []) do
    Client.get(client, "/v1/alert-receivers/#{Client.path_segment(receiver)}/subscriptions",
      params: params
    )
  end

  @spec create_subscription(Client.t(), String.t(), map()) :: Client.result()
  def create_subscription(%Client{} = client, receiver, body) when is_map(body) do
    Client.post(
      client,
      "/v1/alert-receivers/#{Client.path_segment(receiver)}/subscriptions",
      body
    )
  end

  @spec delete_subscription(Client.t(), String.t(), String.t()) :: Client.result()
  def delete_subscription(%Client{} = client, receiver, subscription) do
    Client.delete(
      client,
      "/v1/alert-receivers/#{Client.path_segment(receiver)}/subscriptions/#{Client.path_segment(subscription)}"
    )
  end
end
