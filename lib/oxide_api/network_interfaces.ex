defmodule OxideApi.NetworkInterfaces do
  @moduledoc """
  Network interface endpoints.
  """

  alias OxideApi.Client

  @spec list(Client.t(), keyword()) :: Client.result()
  def list(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/network-interfaces", params: params)
  end

  @spec create(Client.t(), map(), keyword()) :: Client.result()
  def create(%Client{} = client, body, params \\ []) when is_map(body) do
    Client.post(client, "/v1/network-interfaces", body, params: params)
  end

  @spec get(Client.t(), String.t(), keyword()) :: Client.result()
  def get(%Client{} = client, interface, params \\ []) do
    Client.get(client, "/v1/network-interfaces/#{Client.path_segment(interface)}", params: params)
  end

  @spec update(Client.t(), String.t(), map(), keyword()) :: Client.result()
  def update(%Client{} = client, interface, body, params \\ []) when is_map(body) do
    Client.put(client, "/v1/network-interfaces/#{Client.path_segment(interface)}", body,
      params: params
    )
  end

  @spec delete(Client.t(), String.t(), keyword()) :: Client.result()
  def delete(%Client{} = client, interface, params \\ []) do
    Client.delete(client, "/v1/network-interfaces/#{Client.path_segment(interface)}",
      params: params
    )
  end
end
