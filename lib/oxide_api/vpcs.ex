defmodule OxideApi.Vpcs do
  @moduledoc """
  VPC endpoints.
  """

  alias OxideApi.Client

  @spec list(Client.t(), keyword()) :: Client.result()
  def list(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/vpcs", params: params)
  end

  @spec create(Client.t(), map(), keyword()) :: Client.result()
  def create(%Client{} = client, body, params \\ []) when is_map(body) do
    Client.post(client, "/v1/vpcs", body, params: params)
  end

  @spec get(Client.t(), String.t(), keyword()) :: Client.result()
  def get(%Client{} = client, vpc, params \\ []) do
    Client.get(client, "/v1/vpcs/#{Client.path_segment(vpc)}", params: params)
  end

  @spec update(Client.t(), String.t(), map(), keyword()) :: Client.result()
  def update(%Client{} = client, vpc, body, params \\ []) when is_map(body) do
    Client.put(client, "/v1/vpcs/#{Client.path_segment(vpc)}", body, params: params)
  end

  @spec delete(Client.t(), String.t(), keyword()) :: Client.result()
  def delete(%Client{} = client, vpc, params \\ []) do
    Client.delete(client, "/v1/vpcs/#{Client.path_segment(vpc)}", params: params)
  end
end
