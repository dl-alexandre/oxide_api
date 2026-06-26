defmodule OxideApi.VpcRouters do
  @moduledoc """
  VPC router endpoints.
  """

  alias OxideApi.Client

  @spec list(Client.t(), keyword()) :: Client.result()
  def list(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/vpc-routers", params: params)
  end

  @spec create(Client.t(), map(), keyword()) :: Client.result()
  def create(%Client{} = client, body, params \\ []) when is_map(body) do
    Client.post(client, "/v1/vpc-routers", body, params: params)
  end

  @spec get(Client.t(), String.t(), keyword()) :: Client.result()
  def get(%Client{} = client, router, params \\ []) do
    Client.get(client, "/v1/vpc-routers/#{Client.path_segment(router)}", params: params)
  end

  @spec update(Client.t(), String.t(), map(), keyword()) :: Client.result()
  def update(%Client{} = client, router, body, params \\ []) when is_map(body) do
    Client.put(client, "/v1/vpc-routers/#{Client.path_segment(router)}", body, params: params)
  end

  @spec delete(Client.t(), String.t(), keyword()) :: Client.result()
  def delete(%Client{} = client, router, params \\ []) do
    Client.delete(client, "/v1/vpc-routers/#{Client.path_segment(router)}", params: params)
  end
end
