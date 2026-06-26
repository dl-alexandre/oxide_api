defmodule OxideApi.System.Networking do
  @moduledoc """
  System networking endpoints.
  """

  alias OxideApi.Client

  @spec settings(Client.t()) :: Client.result()
  def settings(%Client{} = client), do: Client.get(client, "/v1/system/networking/settings")

  @spec update_settings(Client.t(), map()) :: Client.result()
  def update_settings(%Client{} = client, body) when is_map(body) do
    Client.put(client, "/v1/system/networking/settings", body)
  end

  @spec allow_list(Client.t()) :: Client.result()
  def allow_list(%Client{} = client), do: Client.get(client, "/v1/system/networking/allow-list")

  @spec update_allow_list(Client.t(), map()) :: Client.result()
  def update_allow_list(%Client{} = client, body) when is_map(body) do
    Client.put(client, "/v1/system/networking/allow-list", body)
  end

  @spec inbound_icmp(Client.t()) :: Client.result()
  def inbound_icmp(%Client{} = client),
    do: Client.get(client, "/v1/system/networking/inbound-icmp")

  @spec update_inbound_icmp(Client.t(), map()) :: Client.result()
  def update_inbound_icmp(%Client{} = client, body) when is_map(body) do
    Client.put(client, "/v1/system/networking/inbound-icmp", body)
  end

  @spec bfd_status(Client.t(), keyword()) :: Client.result()
  def bfd_status(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/system/networking/bfd-status", params: params)
  end

  @spec bfd_enable(Client.t(), map()) :: Client.result()
  def bfd_enable(%Client{} = client, body \\ %{}) when is_map(body) do
    Client.post(client, "/v1/system/networking/bfd-enable", body)
  end

  @spec bfd_disable(Client.t(), map()) :: Client.result()
  def bfd_disable(%Client{} = client, body \\ %{}) when is_map(body) do
    Client.post(client, "/v1/system/networking/bfd-disable", body)
  end

  @spec bgp(Client.t()) :: Client.result()
  def bgp(%Client{} = client), do: Client.get(client, "/v1/system/networking/bgp")

  @spec create_bgp(Client.t(), map()) :: Client.result()
  def create_bgp(%Client{} = client, body) when is_map(body) do
    Client.post(client, "/v1/system/networking/bgp", body)
  end

  @spec update_bgp(Client.t(), map()) :: Client.result()
  def update_bgp(%Client{} = client, body) when is_map(body) do
    create_bgp(client, body)
  end

  @spec delete_bgp(Client.t()) :: Client.result()
  def delete_bgp(%Client{} = client) do
    Client.delete(client, "/v1/system/networking/bgp")
  end

  @spec bgp_status(Client.t(), keyword()) :: Client.result()
  def bgp_status(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/system/networking/bgp-status", params: params)
  end

  @spec bgp_imported(Client.t(), keyword()) :: Client.result()
  def bgp_imported(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/system/networking/bgp-imported", params: params)
  end

  @spec bgp_exported(Client.t(), keyword()) :: Client.result()
  def bgp_exported(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/system/networking/bgp-exported", params: params)
  end

  @spec bgp_message_history(Client.t(), keyword()) :: Client.result()
  def bgp_message_history(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/system/networking/bgp-message-history", params: params)
  end

  @spec bgp_announce_sets(Client.t(), keyword()) :: Client.result()
  def bgp_announce_sets(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/system/networking/bgp-announce-set", params: params)
  end

  @spec create_bgp_announce_set(Client.t(), map()) :: Client.result()
  def create_bgp_announce_set(%Client{} = client, body) when is_map(body) do
    Client.post(client, "/v1/system/networking/bgp-announce-set", body)
  end

  @spec update_bgp_announce_set(Client.t(), map()) :: Client.result()
  def update_bgp_announce_set(%Client{} = client, body) when is_map(body) do
    Client.put(client, "/v1/system/networking/bgp-announce-set", body)
  end

  @spec bgp_announce_set(Client.t(), String.t()) :: Client.result()
  def bgp_announce_set(%Client{} = client, announce_set) do
    Client.get(
      client,
      "/v1/system/networking/bgp-announce-set/#{Client.path_segment(announce_set)}"
    )
  end

  @spec delete_bgp_announce_set(Client.t(), String.t()) :: Client.result()
  def delete_bgp_announce_set(%Client{} = client, announce_set) do
    Client.delete(
      client,
      "/v1/system/networking/bgp-announce-set/#{Client.path_segment(announce_set)}"
    )
  end

  @spec bgp_announce_set_announcements(Client.t(), String.t(), keyword()) :: Client.result()
  def bgp_announce_set_announcements(%Client{} = client, announce_set, params \\ []) do
    Client.get(
      client,
      "/v1/system/networking/bgp-announce-set/#{Client.path_segment(announce_set)}/announcement",
      params: params
    )
  end

  @spec bgp_announce_set_announcement(Client.t(), String.t(), map()) :: Client.result()
  def bgp_announce_set_announcement(%Client{} = client, announce_set, body \\ %{})
      when is_map(body) do
    Client.post(
      client,
      "/v1/system/networking/bgp-announce-set/#{Client.path_segment(announce_set)}/announcement",
      body
    )
  end

  @spec address_lots(Client.t(), keyword()) :: Client.result()
  def address_lots(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/system/networking/address-lot", params: params)
  end

  @spec create_address_lot(Client.t(), map()) :: Client.result()
  def create_address_lot(%Client{} = client, body) when is_map(body) do
    Client.post(client, "/v1/system/networking/address-lot", body)
  end

  @spec address_lot(Client.t(), String.t()) :: Client.result()
  def address_lot(%Client{} = client, address_lot) do
    Client.get(client, "/v1/system/networking/address-lot/#{Client.path_segment(address_lot)}")
  end

  @spec delete_address_lot(Client.t(), String.t()) :: Client.result()
  def delete_address_lot(%Client{} = client, address_lot) do
    Client.delete(
      client,
      "/v1/system/networking/address-lot/#{Client.path_segment(address_lot)}"
    )
  end

  @spec address_lot_blocks(Client.t(), String.t(), keyword()) :: Client.result()
  def address_lot_blocks(%Client{} = client, address_lot, params \\ []) do
    Client.get(
      client,
      "/v1/system/networking/address-lot/#{Client.path_segment(address_lot)}/blocks",
      params: params
    )
  end

  @spec loopback_addresses(Client.t(), keyword()) :: Client.result()
  def loopback_addresses(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/system/networking/loopback-address", params: params)
  end

  @spec create_loopback_address(Client.t(), map()) :: Client.result()
  def create_loopback_address(%Client{} = client, body) when is_map(body) do
    Client.post(client, "/v1/system/networking/loopback-address", body)
  end

  @spec loopback_address(Client.t(), String.t(), String.t(), String.t(), String.t()) ::
          Client.result()
  def loopback_address(%Client{} = client, rack_id, switch_slot, address, subnet_mask) do
    Client.get(
      client,
      "/v1/system/networking/loopback-address/#{Client.path_segment(rack_id)}/#{Client.path_segment(switch_slot)}/#{Client.path_segment(address)}/#{Client.path_segment(subnet_mask)}"
    )
  end

  @spec delete_loopback_address(Client.t(), String.t(), String.t(), String.t(), String.t()) ::
          Client.result()
  def delete_loopback_address(%Client{} = client, rack_id, switch_slot, address, subnet_mask) do
    Client.delete(
      client,
      "/v1/system/networking/loopback-address/#{Client.path_segment(rack_id)}/#{Client.path_segment(switch_slot)}/#{Client.path_segment(address)}/#{Client.path_segment(subnet_mask)}"
    )
  end

  @spec switch_port_settings(Client.t(), keyword()) :: Client.result()
  def switch_port_settings(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/system/networking/switch-port-settings", params: params)
  end

  @spec create_switch_port_settings(Client.t(), map()) :: Client.result()
  def create_switch_port_settings(%Client{} = client, body) when is_map(body) do
    Client.post(client, "/v1/system/networking/switch-port-settings", body)
  end

  @spec delete_switch_port_settings(Client.t()) :: Client.result()
  def delete_switch_port_settings(%Client{} = client) do
    Client.delete(client, "/v1/system/networking/switch-port-settings")
  end

  @spec switch_port_setting(Client.t(), String.t()) :: Client.result()
  def switch_port_setting(%Client{} = client, port) do
    Client.get(client, "/v1/system/networking/switch-port-settings/#{Client.path_segment(port)}")
  end

  @spec update_switch_port_setting(Client.t(), String.t(), map()) :: Client.result()
  def update_switch_port_setting(%Client{} = client, port, body) when is_map(body) do
    Client.put(
      client,
      "/v1/system/networking/switch-port-settings/#{Client.path_segment(port)}",
      body
    )
  end
end
