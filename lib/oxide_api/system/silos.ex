defmodule OxideApi.System.Silos do
  @moduledoc """
  System silo endpoints.
  """

  alias OxideApi.Client

  @spec list(Client.t(), keyword()) :: Client.result()
  def list(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/system/silos", params: params)
  end

  @spec create(Client.t(), map()) :: Client.result()
  def create(%Client{} = client, body) when is_map(body) do
    Client.post(client, "/v1/system/silos", body)
  end

  @spec get(Client.t(), String.t()) :: Client.result()
  def get(%Client{} = client, silo) do
    Client.get(client, "/v1/system/silos/#{Client.path_segment(silo)}")
  end

  @spec update(Client.t(), String.t(), map()) :: Client.result()
  def update(%Client{} = client, silo, body) when is_map(body) do
    Client.put(client, "/v1/system/silos/#{Client.path_segment(silo)}", body)
  end

  @spec delete(Client.t(), String.t()) :: Client.result()
  def delete(%Client{} = client, silo) do
    Client.delete(client, "/v1/system/silos/#{Client.path_segment(silo)}")
  end

  @spec policy(Client.t(), String.t()) :: Client.result()
  def policy(%Client{} = client, silo) do
    Client.get(client, "/v1/system/silos/#{Client.path_segment(silo)}/policy")
  end

  @spec update_policy(Client.t(), String.t(), map()) :: Client.result()
  def update_policy(%Client{} = client, silo, body) when is_map(body) do
    Client.put(client, "/v1/system/silos/#{Client.path_segment(silo)}/policy", body)
  end

  @spec quotas(Client.t(), String.t()) :: Client.result()
  def quotas(%Client{} = client, silo) do
    Client.get(client, "/v1/system/silos/#{Client.path_segment(silo)}/quotas")
  end

  @spec update_quotas(Client.t(), String.t(), map()) :: Client.result()
  def update_quotas(%Client{} = client, silo, body) when is_map(body) do
    Client.put(client, "/v1/system/silos/#{Client.path_segment(silo)}/quotas", body)
  end

  @spec ip_pools(Client.t(), String.t(), keyword()) :: Client.result()
  def ip_pools(%Client{} = client, silo, params \\ []) do
    Client.get(client, "/v1/system/silos/#{Client.path_segment(silo)}/ip-pools", params: params)
  end

  @spec subnet_pools(Client.t(), String.t(), keyword()) :: Client.result()
  def subnet_pools(%Client{} = client, silo, params \\ []) do
    Client.get(client, "/v1/system/silos/#{Client.path_segment(silo)}/subnet-pools",
      params: params
    )
  end
end
