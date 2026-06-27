defmodule OxideApi.AshTest do
  use ExUnit.Case, async: false

  alias OxideApi.Ash.{Disk, Domain, FloatingIp, Image, Instance, Project}
  alias OxideApi.Client

  test "maps project API maps into Ash-friendly project records" do
    assert %Project{
             id: "demo-id",
             name: "demo",
             description: "Demo project",
             raw: %{"id" => "demo-id"}
           } =
             Project.from_api(%{
               "id" => "demo-id",
               "name" => "demo",
               "description" => "Demo project"
             })
  end

  test "uses resource names as fallback IDs" do
    assert %Instance{id: "web", name: "web", run_state: "running"} =
             Instance.from_api(%{
               "name" => "web",
               "run_state" => "running"
             })
  end

  test "maps disk fields" do
    assert %Disk{name: "data", size: 1024, state: "attached"} =
             Disk.from_api(%{
               "name" => "data",
               "size" => 1024,
               "state" => "attached"
             })
  end

  test "maps image and floating IP fields" do
    assert %Image{name: "ubuntu", os: "ubuntu", version: "24.04"} =
             Image.from_api(%{
               "name" => "ubuntu",
               "os" => "ubuntu",
               "version" => "24.04"
             })

    assert %FloatingIp{name: "web-public", ip: "198.51.100.10"} =
             FloatingIp.from_api(%{
               "name" => "web-public",
               "ip" => "198.51.100.10"
             })
  end

  test "lists projects through the Ash domain when Ash is available" do
    if OxideApi.Ash.available?() do
      bypass = Bypass.open()

      {:ok, client} =
        Client.new(
          host: "http://localhost:#{bypass.port}",
          token: "oxide-test-token",
          req_options: [retry: false]
        )

      Bypass.expect_once(bypass, "GET", "/v1/projects", fn conn ->
        json(conn, 200, %{"items" => [%{"id" => "demo-id", "name" => "demo"}]})
      end)

      assert {:ok, [%Project{id: "demo-id", name: "demo"}]} =
               Domain.list_projects(client)
    end
  end

  test "lists images through the Ash domain when Ash is available" do
    if OxideApi.Ash.available?() do
      bypass = Bypass.open()

      {:ok, client} =
        Client.new(
          host: "http://localhost:#{bypass.port}",
          token: "oxide-test-token",
          req_options: [retry: false]
        )

      Bypass.expect_once(bypass, "GET", "/v1/images", fn conn ->
        conn = Plug.Conn.fetch_query_params(conn)
        assert conn.query_params["project"] == "prod"
        json(conn, 200, %{"items" => [%{"id" => "image-id", "name" => "ubuntu"}]})
      end)

      assert {:ok, [%Image{id: "image-id", name: "ubuntu"}]} =
               Domain.list_images(client, "prod")
    end
  end

  defp json(conn, status, body) do
    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.resp(status, Jason.encode!(body))
  end
end
