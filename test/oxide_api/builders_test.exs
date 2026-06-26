defmodule OxideApi.BuildersTest do
  use ExUnit.Case, async: true

  alias OxideApi.Builders

  test "builds project bodies" do
    assert Builders.project("demo", description: "Demo") == %{
             "name" => "demo",
             "description" => "Demo"
           }
  end

  test "builds blank disk bodies" do
    assert Builders.blank_disk("data", 21_474_836_480) == %{
             "name" => "data",
             "description" => "data",
             "size" => 21_474_836_480,
             "disk_backend" => %{
               "type" => "distributed",
               "disk_source" => %{
                 "type" => "blank",
                 "block_size" => 4096
               }
             }
           }
  end

  test "builds disk source variants" do
    assert Builders.snapshot_disk_source("snapshot-id") == %{
             "type" => "snapshot",
             "snapshot_id" => "snapshot-id"
           }

    assert Builders.image_disk_source("image-id", read_only: true) == %{
             "type" => "image",
             "image_id" => "image-id",
             "read_only" => true
           }

    assert Builders.disk_from_image("boot", 21_474_836_480, "image-id") == %{
             "name" => "boot",
             "description" => "boot",
             "size" => 21_474_836_480,
             "disk_backend" => %{
               "type" => "distributed",
               "disk_source" => %{"type" => "image", "image_id" => "image-id"}
             }
           }
  end

  test "builds image bodies" do
    source = %{"type" => "snapshot", "snapshot" => "snap"}

    assert Builders.image("ubuntu", source, os: "ubuntu", version: "24.04") == %{
             "name" => "ubuntu",
             "description" => "ubuntu",
             "source" => source,
             "os" => "ubuntu",
             "version" => "24.04"
           }

    assert Builders.image_from_snapshot("ubuntu", "snap-id", "ubuntu", "24.04") == %{
             "name" => "ubuntu",
             "description" => "ubuntu",
             "source" => %{"type" => "snapshot", "id" => "snap-id"},
             "os" => "ubuntu",
             "version" => "24.04"
           }
  end

  test "builds instance bodies" do
    boot_disk = %{"type" => "attach", "name" => "boot"}

    assert Builders.instance("web", "web-1", 2, 4_294_967_296, boot_disk: boot_disk) == %{
             "name" => "web",
             "description" => "web",
             "hostname" => "web-1",
             "ncpus" => 2,
             "memory" => 4_294_967_296,
             "boot_disk" => boot_disk
           }
  end

  test "builds instance attachment helpers" do
    assert Builders.create_disk_attachment("boot", 21_474_836_480) == %{
             "type" => "create",
             "name" => "boot",
             "description" => "boot",
             "size" => 21_474_836_480,
             "disk_backend" => %{
               "type" => "distributed",
               "disk_source" => %{
                 "type" => "blank",
                 "block_size" => 4096
               }
             }
           }

    assert Builders.attach_disk("boot") == %{"type" => "attach", "name" => "boot"}
    assert Builders.default_network_interfaces() == %{"type" => "default_dual_stack"}
    assert Builders.ephemeral_ip() == %{"type" => "ephemeral"}

    assert Builders.floating_ip("public-ip") == %{
             "type" => "floating",
             "floating_ip" => "public-ip"
           }
  end

  test "builds floating IP and network interface bodies" do
    assert Builders.floating_ip_create("public-ip") == %{
             "name" => "public-ip",
             "description" => "public-ip"
           }

    assert Builders.floating_ip_attach("instance", "web") == %{
             "kind" => "instance",
             "parent" => "web"
           }

    assert Builders.network_interface("nic0", "app", "frontend") == %{
             "name" => "nic0",
             "description" => "nic0",
             "vpc_name" => "app",
             "subnet_name" => "frontend"
           }
  end

  test "builds VPC bodies" do
    assert Builders.vpc("app") == %{
             "name" => "app",
             "description" => "app",
             "dns_name" => "app"
           }

    assert Builders.vpc_subnet("frontend", "10.0.0.0/24", custom_router: "router") == %{
             "name" => "frontend",
             "description" => "frontend",
             "ipv4_block" => "10.0.0.0/24",
             "custom_router" => "router"
           }
  end

  test "builds snapshot and firewall bodies" do
    target = Builders.firewall_target("instance", "web")
    filters = Builders.firewall_filters(protocols: ["tcp"], ports: [%{"first" => 443}])
    rule = Builders.firewall_rule("allow-web", targets: [target], filters: filters)

    assert Builders.snapshot("snap", "boot") == %{
             "name" => "snap",
             "description" => "snap",
             "disk" => "boot"
           }

    assert rule == %{
             "name" => "allow-web",
             "description" => "allow-web",
             "action" => "allow",
             "direction" => "inbound",
             "filters" => filters,
             "priority" => 100,
             "status" => "enabled",
             "targets" => [target]
           }

    assert Builders.firewall_rules([rule]) == %{"rules" => [rule]}
  end
end
