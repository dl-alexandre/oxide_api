defmodule OxideApi.MulticastGroups do
  @moduledoc """
  Multicast group endpoints.
  """

  alias OxideApi.Client

  @spec list(Client.t(), keyword()) :: Client.result()
  def list(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/multicast-groups", params: params)
  end

  @spec create(Client.t(), map(), keyword()) :: Client.result()
  def create(%Client{} = client, body, params \\ []) when is_map(body) do
    Client.post(client, "/v1/multicast-groups", body, params: params)
  end

  @spec get(Client.t(), String.t(), keyword()) :: Client.result()
  def get(%Client{} = client, multicast_group, params \\ []) do
    Client.get(client, "/v1/multicast-groups/#{Client.path_segment(multicast_group)}",
      params: params
    )
  end

  @spec update(Client.t(), String.t(), map(), keyword()) :: Client.result()
  def update(%Client{} = client, multicast_group, body, params \\ []) when is_map(body) do
    Client.put(client, "/v1/multicast-groups/#{Client.path_segment(multicast_group)}", body,
      params: params
    )
  end

  @spec delete(Client.t(), String.t(), keyword()) :: Client.result()
  def delete(%Client{} = client, multicast_group, params \\ []) do
    Client.delete(client, "/v1/multicast-groups/#{Client.path_segment(multicast_group)}",
      params: params
    )
  end

  @spec members(Client.t(), String.t(), keyword()) :: Client.result()
  def members(%Client{} = client, multicast_group, params \\ []) do
    Client.get(client, "/v1/multicast-groups/#{Client.path_segment(multicast_group)}/members",
      params: params
    )
  end
end
