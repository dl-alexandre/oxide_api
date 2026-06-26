defmodule OxideApi.System.IpPools do
  @moduledoc """
  System IP pool endpoints.
  """

  alias OxideApi.Client

  @spec list(Client.t(), keyword()) :: Client.result()
  def list(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/system/ip-pools", params: params)
  end

  @spec create(Client.t(), map()) :: Client.result()
  def create(%Client{} = client, body) when is_map(body) do
    Client.post(client, "/v1/system/ip-pools", body)
  end

  @spec get(Client.t(), String.t()) :: Client.result()
  def get(%Client{} = client, pool) do
    Client.get(client, "/v1/system/ip-pools/#{Client.path_segment(pool)}")
  end

  @spec update(Client.t(), String.t(), map()) :: Client.result()
  def update(%Client{} = client, pool, body) when is_map(body) do
    Client.put(client, "/v1/system/ip-pools/#{Client.path_segment(pool)}", body)
  end

  @spec delete(Client.t(), String.t()) :: Client.result()
  def delete(%Client{} = client, pool) do
    Client.delete(client, "/v1/system/ip-pools/#{Client.path_segment(pool)}")
  end

  @spec ranges(Client.t(), String.t(), keyword()) :: Client.result()
  def ranges(%Client{} = client, pool, params \\ []) do
    Client.get(client, "/v1/system/ip-pools/#{Client.path_segment(pool)}/ranges", params: params)
  end

  @spec add_range(Client.t(), String.t(), map()) :: Client.result()
  def add_range(%Client{} = client, pool, body) when is_map(body) do
    Client.post(client, "/v1/system/ip-pools/#{Client.path_segment(pool)}/ranges/add", body)
  end

  @spec remove_range(Client.t(), String.t(), map()) :: Client.result()
  def remove_range(%Client{} = client, pool, body) when is_map(body) do
    Client.post(client, "/v1/system/ip-pools/#{Client.path_segment(pool)}/ranges/remove", body)
  end

  @spec silos(Client.t(), String.t(), keyword()) :: Client.result()
  def silos(%Client{} = client, pool, params \\ []) do
    Client.get(client, "/v1/system/ip-pools/#{Client.path_segment(pool)}/silos", params: params)
  end

  @spec link_silo(Client.t(), String.t(), map()) :: Client.result()
  def link_silo(%Client{} = client, pool, body) when is_map(body) do
    Client.post(client, "/v1/system/ip-pools/#{Client.path_segment(pool)}/silos", body)
  end

  @spec silo(Client.t(), String.t(), String.t()) :: Client.result()
  def silo(%Client{} = client, pool, silo) do
    Client.get(
      client,
      "/v1/system/ip-pools/#{Client.path_segment(pool)}/silos/#{Client.path_segment(silo)}"
    )
  end

  @spec update_silo(Client.t(), String.t(), String.t(), map()) :: Client.result()
  def update_silo(%Client{} = client, pool, silo, body) when is_map(body) do
    Client.put(
      client,
      "/v1/system/ip-pools/#{Client.path_segment(pool)}/silos/#{Client.path_segment(silo)}",
      body
    )
  end

  @spec unlink_silo(Client.t(), String.t(), String.t()) :: Client.result()
  def unlink_silo(%Client{} = client, pool, silo) do
    Client.delete(
      client,
      "/v1/system/ip-pools/#{Client.path_segment(pool)}/silos/#{Client.path_segment(silo)}"
    )
  end

  @spec utilization(Client.t(), String.t()) :: Client.result()
  def utilization(%Client{} = client, pool) do
    Client.get(client, "/v1/system/ip-pools/#{Client.path_segment(pool)}/utilization")
  end
end
