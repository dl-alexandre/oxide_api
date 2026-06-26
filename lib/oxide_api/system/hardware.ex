defmodule OxideApi.System.Hardware do
  @moduledoc """
  System hardware endpoints.
  """

  alias OxideApi.Client

  @spec racks(Client.t(), keyword()) :: Client.result()
  def racks(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/system/hardware/racks", params: params)
  end

  @spec rack(Client.t(), String.t()) :: Client.result()
  def rack(%Client{} = client, rack_id) do
    Client.get(client, "/v1/system/hardware/racks/#{Client.path_segment(rack_id)}")
  end

  @spec rack_membership(Client.t(), String.t()) :: Client.result()
  def rack_membership(%Client{} = client, rack_id) do
    Client.get(client, "/v1/system/hardware/racks/#{Client.path_segment(rack_id)}/membership")
  end

  @spec add_rack_membership(Client.t(), String.t(), map()) :: Client.result()
  def add_rack_membership(%Client{} = client, rack_id, body) when is_map(body) do
    Client.post(
      client,
      "/v1/system/hardware/racks/#{Client.path_segment(rack_id)}/membership/add",
      body
    )
  end

  @spec abort_rack_membership(Client.t(), String.t(), map()) :: Client.result()
  def abort_rack_membership(%Client{} = client, rack_id, body \\ %{}) when is_map(body) do
    Client.post(
      client,
      "/v1/system/hardware/racks/#{Client.path_segment(rack_id)}/membership/abort",
      body
    )
  end

  @spec sleds(Client.t(), keyword()) :: Client.result()
  def sleds(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/system/hardware/sleds", params: params)
  end

  @spec uninitialized_sleds(Client.t(), keyword()) :: Client.result()
  def uninitialized_sleds(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/system/hardware/sleds-uninitialized", params: params)
  end

  @spec sled(Client.t(), String.t()) :: Client.result()
  def sled(%Client{} = client, sled_id) do
    Client.get(client, "/v1/system/hardware/sleds/#{Client.path_segment(sled_id)}")
  end

  @spec sled_disks(Client.t(), String.t(), keyword()) :: Client.result()
  def sled_disks(%Client{} = client, sled_id, params \\ []) do
    Client.get(client, "/v1/system/hardware/sleds/#{Client.path_segment(sled_id)}/disks",
      params: params
    )
  end

  @spec sled_instances(Client.t(), String.t(), keyword()) :: Client.result()
  def sled_instances(%Client{} = client, sled_id, params \\ []) do
    Client.get(client, "/v1/system/hardware/sleds/#{Client.path_segment(sled_id)}/instances",
      params: params
    )
  end

  @spec sled_provision_policy(Client.t(), String.t()) :: Client.result()
  def sled_provision_policy(%Client{} = client, sled_id) do
    Client.get(
      client,
      "/v1/system/hardware/sleds/#{Client.path_segment(sled_id)}/provision-policy"
    )
  end

  @spec update_sled_provision_policy(Client.t(), String.t(), map()) :: Client.result()
  def update_sled_provision_policy(%Client{} = client, sled_id, body) when is_map(body) do
    Client.put(
      client,
      "/v1/system/hardware/sleds/#{Client.path_segment(sled_id)}/provision-policy",
      body
    )
  end

  @spec disks(Client.t(), keyword()) :: Client.result()
  def disks(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/system/hardware/disks", params: params)
  end

  @spec disk(Client.t(), String.t()) :: Client.result()
  def disk(%Client{} = client, disk_id) do
    Client.get(client, "/v1/system/hardware/disks/#{Client.path_segment(disk_id)}")
  end

  @spec unadopted_disks(Client.t(), keyword()) :: Client.result()
  def unadopted_disks(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/system/hardware/disks-unadopted", params: params)
  end

  @spec disk_adoption_requests(Client.t(), keyword()) :: Client.result()
  def disk_adoption_requests(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/system/hardware/disk-adoption-requests", params: params)
  end

  @spec disk_adoption_request(Client.t(), String.t()) :: Client.result()
  def disk_adoption_request(%Client{} = client, physical_disk_adoption_req_id) do
    Client.get(
      client,
      "/v1/system/hardware/disk-adoption-request/#{Client.path_segment(physical_disk_adoption_req_id)}"
    )
  end

  @spec enable_disk_adoption(Client.t(), map()) :: Client.result()
  def enable_disk_adoption(%Client{} = client, body) when is_map(body) do
    Client.put(client, "/v1/system/hardware/disk-adoption-request", body)
  end

  @spec create_disk_adoption_request(Client.t(), map()) :: Client.result()
  def create_disk_adoption_request(%Client{} = client, body) when is_map(body) do
    enable_disk_adoption(client, body)
  end

  @spec disable_disk_adoption(Client.t(), String.t()) :: Client.result()
  def disable_disk_adoption(%Client{} = client, physical_disk_adoption_req_id) do
    Client.delete(
      client,
      "/v1/system/hardware/disk-adoption-request/#{Client.path_segment(physical_disk_adoption_req_id)}"
    )
  end

  @spec switches(Client.t(), keyword()) :: Client.result()
  def switches(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/system/hardware/switches", params: params)
  end

  @spec switch(Client.t(), String.t()) :: Client.result()
  def switch(%Client{} = client, switch_id) do
    Client.get(client, "/v1/system/hardware/switches/#{Client.path_segment(switch_id)}")
  end

  @spec switch_ports(Client.t(), keyword()) :: Client.result()
  def switch_ports(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/system/hardware/switch-port", params: params)
  end

  @spec switch_port_status(Client.t(), String.t()) :: Client.result()
  def switch_port_status(%Client{} = client, port) do
    Client.get(client, "/v1/system/hardware/switch-port/#{Client.path_segment(port)}/status")
  end

  @spec switch_port_settings(Client.t(), String.t()) :: Client.result()
  def switch_port_settings(%Client{} = client, port) do
    Client.get(client, "/v1/system/hardware/switch-port/#{Client.path_segment(port)}/settings")
  end

  @spec apply_switch_port_settings(Client.t(), String.t(), map()) :: Client.result()
  def apply_switch_port_settings(%Client{} = client, port, body) when is_map(body) do
    Client.post(
      client,
      "/v1/system/hardware/switch-port/#{Client.path_segment(port)}/settings",
      body
    )
  end

  @spec update_switch_port_settings(Client.t(), String.t(), map()) :: Client.result()
  def update_switch_port_settings(%Client{} = client, port, body) when is_map(body) do
    apply_switch_port_settings(client, port, body)
  end

  @spec clear_switch_port_settings(Client.t(), String.t()) :: Client.result()
  def clear_switch_port_settings(%Client{} = client, port) do
    Client.delete(
      client,
      "/v1/system/hardware/switch-port/#{Client.path_segment(port)}/settings"
    )
  end

  @spec switch_port_lldp_config(Client.t(), String.t()) :: Client.result()
  def switch_port_lldp_config(%Client{} = client, port) do
    Client.get(client, "/v1/system/hardware/switch-port/#{Client.path_segment(port)}/lldp/config")
  end

  @spec update_switch_port_lldp_config(Client.t(), String.t(), map()) :: Client.result()
  def update_switch_port_lldp_config(%Client{} = client, port, body) when is_map(body) do
    Client.post(
      client,
      "/v1/system/hardware/switch-port/#{Client.path_segment(port)}/lldp/config",
      body
    )
  end

  @spec rack_switch_port_lldp_neighbors(Client.t(), String.t(), String.t(), String.t()) ::
          Client.result()
  def rack_switch_port_lldp_neighbors(%Client{} = client, rack_id, switch_slot, port) do
    Client.get(
      client,
      "/v1/system/hardware/rack-switch-port/#{Client.path_segment(rack_id)}/#{Client.path_segment(switch_slot)}/#{Client.path_segment(port)}/lldp/neighbors"
    )
  end
end
