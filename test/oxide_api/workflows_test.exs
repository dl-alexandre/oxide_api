defmodule OxideApi.WorkflowsTest do
  use ExUnit.Case, async: false

  alias OxideApi.{Client, Error, Workflows}

  setup do
    bypass = Bypass.open()

    {:ok, client} =
      Client.new(
        host: "http://localhost:#{bypass.port}",
        token: "oxide-test-token",
        req_options: [retry: false]
      )

    {:ok, bypass: bypass, client: client}
  end

  test "ensure_project returns an existing project", %{bypass: bypass, client: client} do
    Bypass.expect_once(bypass, "GET", "/v1/projects/demo", fn conn ->
      json(conn, 200, %{"name" => "demo"})
    end)

    assert {:ok, %{"name" => "demo"}} = Workflows.ensure_project(client, "demo")
  end

  test "ensure_project creates a missing project", %{bypass: bypass, client: client} do
    Bypass.expect_once(bypass, "GET", "/v1/projects/demo", fn conn ->
      json(conn, 404, %{"message" => "not found", "error_code" => "not_found"})
    end)

    Bypass.expect_once(bypass, "POST", "/v1/projects", fn conn ->
      assert_json(conn, %{"name" => "demo", "description" => "demo"})
      json(conn, 201, %{"name" => "demo"})
    end)

    assert {:ok, %{"name" => "demo"}} = Workflows.ensure_project(client, "demo")
  end

  test "create_instance_with_disk creates an instance with inline boot disk", %{
    bypass: bypass,
    client: client
  } do
    Bypass.expect_once(bypass, "POST", "/v1/instances", fn conn ->
      conn = Plug.Conn.fetch_query_params(conn)
      assert conn.query_params["project"] == "prod"

      body = read_json(conn)
      assert body["name"] == "web"
      assert body["boot_disk"]["type"] == "create"
      assert body["boot_disk"]["name"] == "boot"
      assert [disk] = body["disks"]
      assert disk["name"] == "boot"

      json(conn, 201, %{"name" => "web"})
    end)

    assert {:ok, %{"name" => "web"}} =
             Workflows.create_instance_with_disk(
               client,
               "prod",
               [name: "web", hostname: "web-1", ncpus: 2, memory: 4_294_967_296],
               name: "boot",
               size: 21_474_836_480
             )
  end

  test "ensure_disk creates a missing blank disk", %{bypass: bypass, client: client} do
    Bypass.expect_once(bypass, "GET", "/v1/disks/data", fn conn ->
      conn = Plug.Conn.fetch_query_params(conn)
      assert conn.query_params["project"] == "prod"
      json(conn, 404, %{"message" => "not found", "error_code" => "not_found"})
    end)

    Bypass.expect_once(bypass, "POST", "/v1/disks", fn conn ->
      conn = Plug.Conn.fetch_query_params(conn)
      assert conn.query_params["project"] == "prod"
      assert %{"name" => "data", "size" => 1024} = read_json(conn)
      json(conn, 201, %{"name" => "data"})
    end)

    assert {:ok, %{"name" => "data"}} =
             Workflows.ensure_disk(client, "prod", name: "data", size: 1024)
  end

  test "ensure_instance returns an existing instance", %{bypass: bypass, client: client} do
    Bypass.expect_once(bypass, "GET", "/v1/instances/web", fn conn ->
      conn = Plug.Conn.fetch_query_params(conn)
      assert conn.query_params["project"] == "prod"
      json(conn, 200, %{"name" => "web"})
    end)

    assert {:ok, %{"name" => "web"}} =
             Workflows.ensure_instance(client, "prod",
               name: "web",
               hostname: "web-1",
               ncpus: 2,
               memory: 4_294_967_296
             )
  end

  test "ensure_image_from_snapshot creates a missing image", %{bypass: bypass, client: client} do
    Bypass.expect_once(bypass, "GET", "/v1/images/ubuntu", fn conn ->
      conn = Plug.Conn.fetch_query_params(conn)
      assert conn.query_params["project"] == "prod"
      json(conn, 404, %{"message" => "not found", "error_code" => "not_found"})
    end)

    Bypass.expect_once(bypass, "POST", "/v1/images", fn conn ->
      conn = Plug.Conn.fetch_query_params(conn)
      assert conn.query_params["project"] == "prod"

      assert_json(conn, %{
        "name" => "ubuntu",
        "description" => "ubuntu",
        "source" => %{"type" => "snapshot", "id" => "snapshot-id"},
        "os" => "ubuntu",
        "version" => "24.04"
      })

      json(conn, 201, %{"name" => "ubuntu"})
    end)

    assert {:ok, %{"name" => "ubuntu"}} =
             Workflows.ensure_image_from_snapshot(client, "prod", "ubuntu", "snapshot-id",
               os: "ubuntu",
               version: "24.04"
             )
  end

  test "ensure_floating_ip creates a missing floating IP", %{bypass: bypass, client: client} do
    Bypass.expect_once(bypass, "GET", "/v1/floating-ips/web-public", fn conn ->
      conn = Plug.Conn.fetch_query_params(conn)
      assert conn.query_params["project"] == "prod"
      json(conn, 404, %{"message" => "not found", "error_code" => "not_found"})
    end)

    Bypass.expect_once(bypass, "POST", "/v1/floating-ips", fn conn ->
      conn = Plug.Conn.fetch_query_params(conn)
      assert conn.query_params["project"] == "prod"
      assert_json(conn, %{"name" => "web-public", "description" => "web-public"})
      json(conn, 201, %{"name" => "web-public"})
    end)

    assert {:ok, %{"name" => "web-public"}} =
             Workflows.ensure_floating_ip(client, "prod", "web-public")
  end

  test "ensure_vpc_firewall_rules updates changed rules", %{bypass: bypass, client: client} do
    rule = %{"name" => "allow-https", "action" => "allow"}

    Bypass.expect_once(bypass, "GET", "/v1/vpc-firewall-rules", fn conn ->
      conn = Plug.Conn.fetch_query_params(conn)
      assert conn.query_params["project"] == "prod"
      assert conn.query_params["vpc"] == "app"
      json(conn, 200, %{"rules" => []})
    end)

    Bypass.expect_once(bypass, "PUT", "/v1/vpc-firewall-rules", fn conn ->
      conn = Plug.Conn.fetch_query_params(conn)
      assert conn.query_params["project"] == "prod"
      assert conn.query_params["vpc"] == "app"
      assert_json(conn, %{"rules" => [rule]})
      json(conn, 200, %{"rules" => [rule]})
    end)

    assert {:ok, %{"rules" => [^rule]}} =
             Workflows.ensure_vpc_firewall_rules(client, "prod", "app", [rule])
  end

  test "ensure_vpc_and_subnet creates missing VPC and subnet", %{bypass: bypass, client: client} do
    Bypass.expect_once(bypass, "GET", "/v1/vpcs/app", fn conn ->
      conn = Plug.Conn.fetch_query_params(conn)
      assert conn.query_params["project"] == "prod"
      json(conn, 404, %{"message" => "not found", "error_code" => "not_found"})
    end)

    Bypass.expect_once(bypass, "POST", "/v1/vpcs", fn conn ->
      conn = Plug.Conn.fetch_query_params(conn)
      assert conn.query_params["project"] == "prod"
      assert_json(conn, %{"name" => "app", "description" => "app", "dns_name" => "app"})
      json(conn, 201, %{"name" => "app"})
    end)

    Bypass.expect_once(bypass, "GET", "/v1/vpc-subnets/frontend", fn conn ->
      conn = Plug.Conn.fetch_query_params(conn)
      assert conn.query_params["project"] == "prod"
      assert conn.query_params["vpc"] == "app"
      json(conn, 404, %{"message" => "not found", "error_code" => "not_found"})
    end)

    Bypass.expect_once(bypass, "POST", "/v1/vpc-subnets", fn conn ->
      conn = Plug.Conn.fetch_query_params(conn)
      assert conn.query_params["project"] == "prod"
      assert conn.query_params["vpc"] == "app"

      assert_json(conn, %{
        "name" => "frontend",
        "description" => "frontend",
        "ipv4_block" => "10.0.0.0/24"
      })

      json(conn, 201, %{"name" => "frontend"})
    end)

    assert {:ok, %{vpc: %{"name" => "app"}, subnet: %{"name" => "frontend"}}} =
             Workflows.ensure_vpc_and_subnet(
               client,
               "prod",
               "app",
               name: "frontend",
               ipv4_block: "10.0.0.0/24"
             )
  end

  test "create_image_from_snapshot builds and creates an image", %{bypass: bypass, client: client} do
    Bypass.expect_once(bypass, "POST", "/v1/images", fn conn ->
      conn = Plug.Conn.fetch_query_params(conn)
      assert conn.query_params["project"] == "prod"

      assert_json(conn, %{
        "name" => "ubuntu",
        "description" => "ubuntu",
        "source" => %{"type" => "snapshot", "id" => "snapshot-id"},
        "os" => "ubuntu",
        "version" => "24.04"
      })

      json(conn, 201, %{"name" => "ubuntu"})
    end)

    assert {:ok, %{"name" => "ubuntu"}} =
             Workflows.create_image_from_snapshot(
               client,
               "prod",
               "ubuntu",
               "snapshot-id",
               os: "ubuntu",
               version: "24.04"
             )
  end

  test "create_image_from_snapshot validates required options", %{client: client} do
    assert {:error, %Error{error_code: "configuration_error"}} =
             Workflows.create_image_from_snapshot(client, "prod", "ubuntu", "snapshot-id", [])
  end

  defp assert_json(conn, expected) do
    assert read_json(conn) == expected
  end

  defp read_json(conn) do
    {:ok, body, _conn} = Plug.Conn.read_body(conn)
    Jason.decode!(body)
  end

  defp json(conn, status, body) do
    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.resp(status, Jason.encode!(body))
  end
end
