defmodule OxideApi.InternetGateways do
  @moduledoc """
  Internet gateway endpoints.
  """

  alias OxideApi.Client

  @spec list(Client.t(), keyword()) :: Client.result()
  def list(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/internet-gateways", params: params)
  end

  @spec create(Client.t(), map(), keyword()) :: Client.result()
  def create(%Client{} = client, body, params \\ []) when is_map(body) do
    Client.post(client, "/v1/internet-gateways", body, params: params)
  end

  @spec get(Client.t(), String.t(), keyword()) :: Client.result()
  def get(%Client{} = client, gateway, params \\ []) do
    Client.get(client, "/v1/internet-gateways/#{Client.path_segment(gateway)}", params: params)
  end

  @spec update(Client.t(), String.t(), map(), keyword()) :: Client.result()
  def update(%Client{} = client, gateway, body, params \\ []) when is_map(body) do
    Client.put(client, "/v1/internet-gateways/#{Client.path_segment(gateway)}", body,
      params: params
    )
  end

  @spec delete(Client.t(), String.t(), keyword()) :: Client.result()
  def delete(%Client{} = client, gateway, params \\ []) do
    Client.delete(client, "/v1/internet-gateways/#{Client.path_segment(gateway)}", params: params)
  end
end
