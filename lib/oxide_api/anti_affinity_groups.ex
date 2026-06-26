defmodule OxideApi.AntiAffinityGroups do
  @moduledoc """
  Anti-affinity group endpoints.
  """

  alias OxideApi.Client

  @spec list(Client.t(), keyword()) :: Client.result()
  def list(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/anti-affinity-groups", params: params)
  end

  @spec create(Client.t(), map(), keyword()) :: Client.result()
  def create(%Client{} = client, body, params \\ []) when is_map(body) do
    Client.post(client, "/v1/anti-affinity-groups", body, params: params)
  end

  @spec get(Client.t(), String.t(), keyword()) :: Client.result()
  def get(%Client{} = client, anti_affinity_group, params \\ []) do
    Client.get(
      client,
      "/v1/anti-affinity-groups/#{Client.path_segment(anti_affinity_group)}",
      params: params
    )
  end

  @spec update(Client.t(), String.t(), map(), keyword()) :: Client.result()
  def update(%Client{} = client, anti_affinity_group, body, params \\ []) when is_map(body) do
    Client.put(
      client,
      "/v1/anti-affinity-groups/#{Client.path_segment(anti_affinity_group)}",
      body,
      params: params
    )
  end

  @spec delete(Client.t(), String.t(), keyword()) :: Client.result()
  def delete(%Client{} = client, anti_affinity_group, params \\ []) do
    Client.delete(
      client,
      "/v1/anti-affinity-groups/#{Client.path_segment(anti_affinity_group)}",
      params: params
    )
  end

  @spec members(Client.t(), String.t(), keyword()) :: Client.result()
  def members(%Client{} = client, anti_affinity_group, params \\ []) do
    Client.get(
      client,
      "/v1/anti-affinity-groups/#{Client.path_segment(anti_affinity_group)}/members",
      params: params
    )
  end

  @spec get_instance_member(Client.t(), String.t(), String.t(), keyword()) :: Client.result()
  def get_instance_member(%Client{} = client, anti_affinity_group, instance, params \\ []) do
    Client.get(
      client,
      "/v1/anti-affinity-groups/#{Client.path_segment(anti_affinity_group)}/members/instance/#{Client.path_segment(instance)}",
      params: params
    )
  end

  @spec add_instance_member(Client.t(), String.t(), String.t(), keyword()) :: Client.result()
  def add_instance_member(%Client{} = client, anti_affinity_group, instance, params \\ []) do
    Client.request(
      client,
      :post,
      "/v1/anti-affinity-groups/#{Client.path_segment(anti_affinity_group)}/members/instance/#{Client.path_segment(instance)}",
      params: params
    )
  end

  @spec delete_instance_member(Client.t(), String.t(), String.t(), keyword()) :: Client.result()
  def delete_instance_member(%Client{} = client, anti_affinity_group, instance, params \\ []) do
    Client.delete(
      client,
      "/v1/anti-affinity-groups/#{Client.path_segment(anti_affinity_group)}/members/instance/#{Client.path_segment(instance)}",
      params: params
    )
  end
end
