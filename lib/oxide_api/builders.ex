defmodule OxideApi.Builders do
  @moduledoc """
  Optional request-body builders for common create calls.

  These helpers return plain maps. They are conveniences only; every resource
  function still accepts raw maps so callers can use newly-added API fields
  before this library grows a typed wrapper for them.
  """

  @type json_map :: %{String.t() => term()}

  @doc """
  Builds a project create body.
  """
  @spec project(String.t(), keyword()) :: json_map()
  def project(name, opts \\ []) do
    %{
      "name" => name,
      "description" => Keyword.get(opts, :description, name)
    }
  end

  @doc """
  Builds a blank distributed disk create body.
  """
  @spec blank_disk(String.t(), non_neg_integer(), keyword()) :: json_map()
  def blank_disk(name, size, opts \\ []) do
    block_size = Keyword.get(opts, :block_size, 4096)

    %{
      "name" => name,
      "description" => Keyword.get(opts, :description, name),
      "size" => size,
      "disk_backend" => %{
        "type" => Keyword.get(opts, :backend_type, "distributed"),
        "disk_source" => %{
          "type" => "blank",
          "block_size" => block_size
        }
      }
    }
  end

  @doc """
  Builds a distributed disk source from a snapshot ID.
  """
  @spec snapshot_disk_source(String.t(), keyword()) :: json_map()
  def snapshot_disk_source(snapshot_id, opts \\ []) do
    %{
      "type" => "snapshot",
      "snapshot_id" => snapshot_id
    }
    |> put_optional("read_only", opts[:read_only])
  end

  @doc """
  Builds a distributed disk source from an image ID.
  """
  @spec image_disk_source(String.t(), keyword()) :: json_map()
  def image_disk_source(image_id, opts \\ []) do
    %{
      "type" => "image",
      "image_id" => image_id
    }
    |> put_optional("read_only", opts[:read_only])
  end

  @doc """
  Builds a distributed disk source for bulk import.
  """
  @spec importing_blocks_disk_source(keyword()) :: json_map()
  def importing_blocks_disk_source(opts \\ []) do
    %{
      "type" => "importing_blocks",
      "block_size" => Keyword.get(opts, :block_size, 4096)
    }
  end

  @doc """
  Builds a disk backend with the given distributed disk source.
  """
  @spec distributed_disk_backend(map()) :: json_map()
  def distributed_disk_backend(disk_source) when is_map(disk_source) do
    %{
      "type" => "distributed",
      "disk_source" => disk_source
    }
  end

  @doc """
  Builds a disk create body from an image ID.
  """
  @spec disk_from_image(String.t(), non_neg_integer(), String.t(), keyword()) :: json_map()
  def disk_from_image(name, size, image_id, opts \\ []) do
    disk(name, size, image_disk_source(image_id, opts), opts)
  end

  @doc """
  Builds a disk create body from a snapshot ID.
  """
  @spec disk_from_snapshot(String.t(), non_neg_integer(), String.t(), keyword()) :: json_map()
  def disk_from_snapshot(name, size, snapshot_id, opts \\ []) do
    disk(name, size, snapshot_disk_source(snapshot_id, opts), opts)
  end

  @doc """
  Builds a disk create body from a distributed disk source.
  """
  @spec disk(String.t(), non_neg_integer(), map(), keyword()) :: json_map()
  def disk(name, size, disk_source, opts \\ []) when is_map(disk_source) do
    %{
      "name" => name,
      "description" => Keyword.get(opts, :description, name),
      "size" => size,
      "disk_backend" => distributed_disk_backend(disk_source)
    }
  end

  @doc """
  Builds an image create body.

  Pass the API-shaped image source map as `source`.
  """
  @spec image(String.t(), map(), keyword()) :: json_map()
  def image(name, source, opts \\ []) when is_map(source) do
    %{
      "name" => name,
      "description" => Keyword.get(opts, :description, name),
      "source" => source
    }
    |> put_optional("description", opts[:description])
    |> put_optional("os", opts[:os])
    |> put_optional("version", opts[:version])
  end

  @doc """
  Builds an image create body whose source is a snapshot ID.
  """
  @spec image_from_snapshot(String.t(), String.t(), String.t(), String.t(), keyword()) ::
          json_map()
  def image_from_snapshot(name, snapshot_id, os, version, opts \\ []) do
    image(name, %{"type" => "snapshot", "id" => snapshot_id},
      description: Keyword.get(opts, :description, name),
      os: os,
      version: version
    )
  end

  @doc """
  Builds an instance create body.
  """
  @spec instance(String.t(), String.t(), pos_integer(), non_neg_integer(), keyword()) ::
          json_map()
  def instance(name, hostname, ncpus, memory, opts \\ []) do
    %{
      "name" => name,
      "description" => Keyword.get(opts, :description, name),
      "hostname" => hostname,
      "ncpus" => ncpus,
      "memory" => memory
    }
    |> put_optional("anti_affinity_groups", opts[:anti_affinity_groups])
    |> put_optional("auto_restart_policy", opts[:auto_restart_policy])
    |> put_optional("boot_disk", opts[:boot_disk])
    |> put_optional("cpu_platform", opts[:cpu_platform])
    |> put_optional("disks", opts[:disks])
    |> put_optional("enable_jumbo_frames", opts[:enable_jumbo_frames])
    |> put_optional("external_ips", opts[:external_ips])
    |> put_optional("multicast_groups", opts[:multicast_groups])
    |> put_optional("network_interfaces", opts[:network_interfaces])
    |> put_optional("ssh_public_keys", opts[:ssh_public_keys])
    |> put_optional("start", opts[:start])
    |> put_optional("user_data", opts[:user_data])
  end

  @doc """
  Builds an instance disk attachment that creates a new blank disk.
  """
  @spec create_disk_attachment(String.t(), non_neg_integer(), keyword()) :: json_map()
  def create_disk_attachment(name, size, opts \\ []) do
    name
    |> blank_disk(size, opts)
    |> Map.put("type", "create")
  end

  @doc """
  Builds an instance disk attachment for an existing disk.
  """
  @spec attach_disk(String.t()) :: json_map()
  def attach_disk(name), do: %{"type" => "attach", "name" => name}

  @doc """
  Builds the default instance network interface attachment.
  """
  @spec default_network_interfaces(String.t()) :: json_map()
  def default_network_interfaces(type \\ "default_dual_stack"), do: %{"type" => type}

  @doc """
  Builds an ephemeral external IP attachment for an instance.
  """
  @spec ephemeral_ip(keyword()) :: json_map()
  def ephemeral_ip(opts \\ []) do
    %{"type" => "ephemeral"}
    |> put_optional("pool_selector", opts[:pool_selector])
  end

  @doc """
  Builds a floating external IP attachment for an instance.
  """
  @spec floating_ip(String.t()) :: json_map()
  def floating_ip(name), do: %{"type" => "floating", "floating_ip" => name}

  @doc """
  Builds a floating IP create body.
  """
  @spec floating_ip_create(String.t(), keyword()) :: json_map()
  def floating_ip_create(name, opts \\ []) do
    %{
      "name" => name,
      "description" => Keyword.get(opts, :description, name)
    }
    |> put_optional("address_allocator", opts[:address_allocator])
  end

  @doc """
  Builds a floating IP attach body.
  """
  @spec floating_ip_attach(String.t(), String.t()) :: json_map()
  def floating_ip_attach(kind, parent), do: %{"kind" => kind, "parent" => parent}

  @doc """
  Builds a network interface create body.
  """
  @spec network_interface(String.t(), String.t(), String.t(), keyword()) :: json_map()
  def network_interface(name, vpc_name, subnet_name, opts \\ []) do
    %{
      "name" => name,
      "description" => Keyword.get(opts, :description, name),
      "vpc_name" => vpc_name,
      "subnet_name" => subnet_name
    }
    |> put_optional("ip_config", opts[:ip_config])
  end

  @doc """
  Builds a snapshot create body for a disk.
  """
  @spec snapshot(String.t(), String.t(), keyword()) :: json_map()
  def snapshot(name, disk, opts \\ []) do
    %{
      "name" => name,
      "description" => Keyword.get(opts, :description, name),
      "disk" => disk
    }
  end

  @doc """
  Builds a VPC create body.
  """
  @spec vpc(String.t(), keyword()) :: json_map()
  def vpc(name, opts \\ []) do
    %{
      "name" => name,
      "description" => Keyword.get(opts, :description, name),
      "dns_name" => Keyword.get(opts, :dns_name, name)
    }
    |> put_optional("ipv6_prefix", opts[:ipv6_prefix])
  end

  @doc """
  Builds a VPC subnet create body.
  """
  @spec vpc_subnet(String.t(), String.t(), keyword()) :: json_map()
  def vpc_subnet(name, ipv4_block, opts \\ []) do
    %{
      "name" => name,
      "description" => Keyword.get(opts, :description, name),
      "ipv4_block" => ipv4_block
    }
    |> put_optional("custom_router", opts[:custom_router])
    |> put_optional("ipv6_block", opts[:ipv6_block])
  end

  @doc """
  Builds a VPC firewall rule update body.
  """
  @spec firewall_rule(String.t(), keyword()) :: json_map()
  def firewall_rule(name, opts \\ []) do
    %{
      "name" => name,
      "description" => Keyword.get(opts, :description, name),
      "action" => Keyword.get(opts, :action, "allow"),
      "direction" => Keyword.get(opts, :direction, "inbound"),
      "filters" => Keyword.get(opts, :filters, %{}),
      "priority" => Keyword.get(opts, :priority, 100),
      "status" => Keyword.get(opts, :status, "enabled"),
      "targets" => Keyword.fetch!(opts, :targets)
    }
  end

  @doc """
  Builds a VPC firewall rules replacement body.
  """
  @spec firewall_rules([map()]) :: json_map()
  def firewall_rules(rules) when is_list(rules), do: %{"rules" => rules}

  @doc """
  Builds a VPC firewall rule target.
  """
  @spec firewall_target(String.t(), String.t()) :: json_map()
  def firewall_target(type, value), do: %{"type" => type, "value" => value}

  @doc """
  Builds a VPC firewall protocol filter.
  """
  @spec firewall_filters(keyword()) :: json_map()
  def firewall_filters(opts \\ []) do
    %{}
    |> put_optional("hosts", opts[:hosts])
    |> put_optional("ports", opts[:ports])
    |> put_optional("protocols", opts[:protocols])
  end

  defp put_optional(map, _key, nil), do: map
  defp put_optional(map, key, value), do: Map.put(map, key, value)
end
