defmodule OxideApi.Instances do
  @moduledoc """
  Instance endpoints.
  """

  alias OxideApi.Client

  @spec list(Client.t(), keyword()) :: Client.result()
  def list(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/instances", params: params)
  end

  @spec stream(Client.t(), keyword() | map()) :: Enumerable.t()
  def stream(%Client{} = client, params \\ []) do
    Client.stream_items(client, "/v1/instances", params)
  end

  @spec create(Client.t(), map(), keyword()) :: Client.result()
  def create(%Client{} = client, body, params \\ []) when is_map(body) do
    Client.post(client, "/v1/instances", body, params: params)
  end

  @spec get(Client.t(), String.t(), keyword()) :: Client.result()
  def get(%Client{} = client, instance, params \\ []) do
    Client.get(client, "/v1/instances/#{Client.path_segment(instance)}", params: params)
  end

  @spec update(Client.t(), String.t(), map(), keyword()) :: Client.result()
  def update(%Client{} = client, instance, body, params \\ []) when is_map(body) do
    Client.put(client, "/v1/instances/#{Client.path_segment(instance)}", body, params: params)
  end

  @spec delete(Client.t(), String.t(), keyword()) :: Client.result()
  def delete(%Client{} = client, instance, params \\ []) do
    Client.delete(client, "/v1/instances/#{Client.path_segment(instance)}", params: params)
  end

  @spec start(Client.t(), String.t(), keyword()) :: Client.result()
  def start(%Client{} = client, instance, params \\ []) do
    Client.post(client, "/v1/instances/#{Client.path_segment(instance)}/start", %{},
      params: params
    )
  end

  @spec stop(Client.t(), String.t(), keyword()) :: Client.result()
  def stop(%Client{} = client, instance, params \\ []) do
    Client.post(client, "/v1/instances/#{Client.path_segment(instance)}/stop", %{},
      params: params
    )
  end

  @spec reboot(Client.t(), String.t(), keyword()) :: Client.result()
  def reboot(%Client{} = client, instance, params \\ []) do
    Client.post(client, "/v1/instances/#{Client.path_segment(instance)}/reboot", %{},
      params: params
    )
  end

  @spec list_disks(Client.t(), String.t(), keyword()) :: Client.result()
  def list_disks(%Client{} = client, instance, params \\ []) do
    Client.get(client, "/v1/instances/#{Client.path_segment(instance)}/disks", params: params)
  end

  @spec attach_disk(Client.t(), String.t(), map(), keyword()) :: Client.result()
  def attach_disk(%Client{} = client, instance, body, params \\ []) when is_map(body) do
    Client.post(client, "/v1/instances/#{Client.path_segment(instance)}/disks/attach", body,
      params: params
    )
  end

  @spec detach_disk(Client.t(), String.t(), map(), keyword()) :: Client.result()
  def detach_disk(%Client{} = client, instance, body, params \\ []) when is_map(body) do
    Client.post(client, "/v1/instances/#{Client.path_segment(instance)}/disks/detach", body,
      params: params
    )
  end

  @spec list_external_ips(Client.t(), String.t(), keyword()) :: Client.result()
  def list_external_ips(%Client{} = client, instance, params \\ []) do
    Client.get(client, "/v1/instances/#{Client.path_segment(instance)}/external-ips",
      params: params
    )
  end

  @spec attach_ephemeral_ip(Client.t(), String.t(), map(), keyword()) :: Client.result()
  def attach_ephemeral_ip(%Client{} = client, instance, body, params \\ []) when is_map(body) do
    Client.post(
      client,
      "/v1/instances/#{Client.path_segment(instance)}/external-ips/ephemeral",
      body,
      params: params
    )
  end

  @spec external_subnets(Client.t(), String.t(), keyword()) :: Client.result()
  def external_subnets(%Client{} = client, instance, params \\ []) do
    Client.get(client, "/v1/instances/#{Client.path_segment(instance)}/external-subnets",
      params: params
    )
  end

  @spec delete_ephemeral_ip(Client.t(), String.t(), keyword()) :: Client.result()
  def delete_ephemeral_ip(%Client{} = client, instance, params \\ []) do
    Client.delete(client, "/v1/instances/#{Client.path_segment(instance)}/external-ips/ephemeral",
      params: params
    )
  end

  @spec serial_console(Client.t(), String.t(), keyword()) :: Client.result()
  def serial_console(%Client{} = client, instance, params \\ []) do
    Client.get(client, "/v1/instances/#{Client.path_segment(instance)}/serial-console",
      params: params
    )
  end

  @spec serial_console_stream(Client.t(), String.t(), keyword()) :: Client.result()
  def serial_console_stream(%Client{} = client, instance, params \\ []) do
    Client.get(client, "/v1/instances/#{Client.path_segment(instance)}/serial-console/stream",
      params: params
    )
  end

  @spec ssh_public_keys(Client.t(), String.t(), keyword()) :: Client.result()
  def ssh_public_keys(%Client{} = client, instance, params \\ []) do
    Client.get(client, "/v1/instances/#{Client.path_segment(instance)}/ssh-public-keys",
      params: params
    )
  end

  @spec affinity_groups(Client.t(), String.t(), keyword()) :: Client.result()
  def affinity_groups(%Client{} = client, instance, params \\ []) do
    Client.get(client, "/v1/instances/#{Client.path_segment(instance)}/affinity-groups",
      params: params
    )
  end

  @spec anti_affinity_groups(Client.t(), String.t(), keyword()) :: Client.result()
  def anti_affinity_groups(%Client{} = client, instance, params \\ []) do
    Client.get(client, "/v1/instances/#{Client.path_segment(instance)}/anti-affinity-groups",
      params: params
    )
  end

  @spec multicast_groups(Client.t(), String.t(), keyword()) :: Client.result()
  def multicast_groups(%Client{} = client, instance, params \\ []) do
    Client.get(client, "/v1/instances/#{Client.path_segment(instance)}/multicast-groups",
      params: params
    )
  end

  @spec multicast_group(Client.t(), String.t(), String.t(), keyword()) :: Client.result()
  def multicast_group(%Client{} = client, instance, multicast_group, params \\ []) do
    Client.get(
      client,
      "/v1/instances/#{Client.path_segment(instance)}/multicast-groups/#{Client.path_segment(multicast_group)}",
      params: params
    )
  end

  @spec join_multicast_group(Client.t(), String.t(), String.t(), map(), keyword()) ::
          Client.result()
  def join_multicast_group(%Client{} = client, instance, multicast_group, body, params \\ [])
      when is_map(body) do
    Client.put(
      client,
      "/v1/instances/#{Client.path_segment(instance)}/multicast-groups/#{Client.path_segment(multicast_group)}",
      body,
      params: params
    )
  end

  @spec leave_multicast_group(Client.t(), String.t(), String.t(), keyword()) :: Client.result()
  def leave_multicast_group(%Client{} = client, instance, multicast_group, params \\ []) do
    Client.delete(
      client,
      "/v1/instances/#{Client.path_segment(instance)}/multicast-groups/#{Client.path_segment(multicast_group)}",
      params: params
    )
  end
end
