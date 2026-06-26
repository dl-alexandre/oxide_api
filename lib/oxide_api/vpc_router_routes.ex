defmodule OxideApi.VpcRouterRoutes do
  @moduledoc """
  VPC router route endpoints.
  """

  alias OxideApi.Client

  @spec list(Client.t(), keyword()) :: Client.result()
  def list(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/vpc-router-routes", params: params)
  end

  @spec create(Client.t(), map(), keyword()) :: Client.result()
  def create(%Client{} = client, body, params \\ []) when is_map(body) do
    Client.post(client, "/v1/vpc-router-routes", body, params: params)
  end

  @spec get(Client.t(), String.t(), keyword()) :: Client.result()
  def get(%Client{} = client, route, params \\ []) do
    Client.get(client, "/v1/vpc-router-routes/#{Client.path_segment(route)}", params: params)
  end

  @spec update(Client.t(), String.t(), map(), keyword()) :: Client.result()
  def update(%Client{} = client, route, body, params \\ []) when is_map(body) do
    Client.put(client, "/v1/vpc-router-routes/#{Client.path_segment(route)}", body,
      params: params
    )
  end

  @spec delete(Client.t(), String.t(), keyword()) :: Client.result()
  def delete(%Client{} = client, route, params \\ []) do
    Client.delete(client, "/v1/vpc-router-routes/#{Client.path_segment(route)}", params: params)
  end
end
