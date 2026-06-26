defmodule OxideApi.ExternalSubnets do
  @moduledoc """
  External subnet endpoints.
  """

  alias OxideApi.Client

  @spec list(Client.t(), keyword()) :: Client.result()
  def list(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/external-subnets", params: params)
  end

  @spec create(Client.t(), map(), keyword()) :: Client.result()
  def create(%Client{} = client, body, params \\ []) when is_map(body) do
    Client.post(client, "/v1/external-subnets", body, params: params)
  end

  @spec get(Client.t(), String.t(), keyword()) :: Client.result()
  def get(%Client{} = client, external_subnet, params \\ []) do
    Client.get(client, "/v1/external-subnets/#{Client.path_segment(external_subnet)}",
      params: params
    )
  end

  @spec update(Client.t(), String.t(), map(), keyword()) :: Client.result()
  def update(%Client{} = client, external_subnet, body, params \\ []) when is_map(body) do
    Client.put(client, "/v1/external-subnets/#{Client.path_segment(external_subnet)}", body,
      params: params
    )
  end

  @spec delete(Client.t(), String.t(), keyword()) :: Client.result()
  def delete(%Client{} = client, external_subnet, params \\ []) do
    Client.delete(client, "/v1/external-subnets/#{Client.path_segment(external_subnet)}",
      params: params
    )
  end

  @spec attach(Client.t(), String.t(), map(), keyword()) :: Client.result()
  def attach(%Client{} = client, external_subnet, body, params \\ []) when is_map(body) do
    Client.post(
      client,
      "/v1/external-subnets/#{Client.path_segment(external_subnet)}/attach",
      body,
      params: params
    )
  end

  @spec detach(Client.t(), String.t(), map(), keyword()) :: Client.result()
  def detach(%Client{} = client, external_subnet, body \\ %{}, params \\ []) when is_map(body) do
    Client.post(
      client,
      "/v1/external-subnets/#{Client.path_segment(external_subnet)}/detach",
      body,
      params: params
    )
  end
end
