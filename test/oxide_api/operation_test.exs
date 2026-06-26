defmodule OxideApi.OperationTest do
  use ExUnit.Case, async: false

  alias OxideApi.{Client, Operation}

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

  test "fetches generated operation metadata" do
    assert {:ok,
            %{
              method: "get",
              path: "/v1/projects",
              operation_id: "project_list",
              paginated: true,
              item_schema: "Project"
            }} = Operation.fetch(:project_list)

    assert :error = Operation.fetch(:does_not_exist)
  end

  test "exposes generated request, response, and parameter metadata" do
    assert Operation.request_schema(:timeseries_query) == "TimeseriesQuery"
    assert Operation.response_schema(:timeseries_query) == "OxqlQueryResult"
    assert Operation.response_status(:timeseries_query) == "200"

    assert [
             %{
               name: "project",
               in: "query",
               required: true,
               schema: "NameOrId"
             }
           ] = Operation.query_parameters(:timeseries_query)

    assert [%{name: "instance", in: "path", required: true}] =
             Operation.path_parameters(:instance_view)
  end

  test "renders schema paths with escaped path params" do
    assert "/v1/instances/name%2Fwith%2Fslash/disks" =
             Operation.render_path("/v1/instances/{instance}/disks",
               instance: "name/with/slash"
             )
  end

  test "requests an operation by operation id with path and query params", %{
    bypass: bypass,
    client: client
  } do
    Bypass.expect_once(bypass, "GET", "/v1/instances/web%2Fone", fn conn ->
      conn = Plug.Conn.fetch_query_params(conn)
      assert conn.query_params["project"] == "prod"

      json(conn, 200, %{"name" => "web/one"})
    end)

    assert {:ok, %{"name" => "web/one"}} =
             Operation.request(client, :instance_view,
               path_params: [instance: "web/one"],
               params: [project: "prod"]
             )
  end

  test "requests an operation with JSON body metadata", %{bypass: bypass, client: client} do
    Bypass.expect_once(bypass, "POST", "/v1/timeseries/query", fn conn ->
      conn = Plug.Conn.fetch_query_params(conn)
      headers = Map.new(conn.req_headers)

      assert conn.query_params["project"] == "prod"
      assert headers["content-type"] =~ "application/json"

      {:ok, body, conn} = Plug.Conn.read_body(conn)
      assert Jason.decode!(body) == %{"query" => "get sled_cpu:usage"}

      json(conn, 200, %{"tables" => []})
    end)

    assert {:ok, %{"tables" => []}} =
             OxideApi.request_operation(client, :timeseries_query,
               params: [project: "prod"],
               request_body: %{"query" => "get sled_cpu:usage"}
             )
  end

  test "requests an operation with form body metadata", %{bypass: bypass} do
    {:ok, client} =
      Client.new_unauthenticated(
        host: "http://localhost:#{bypass.port}",
        req_options: [retry: false]
      )

    Bypass.expect_once(bypass, "POST", "/device/auth", fn conn ->
      headers = Map.new(conn.req_headers)
      refute Map.has_key?(headers, "authorization")
      assert headers["content-type"] =~ "application/x-www-form-urlencoded"

      {:ok, body, conn} = Plug.Conn.read_body(conn)
      assert URI.decode_query(body) == %{"client_id" => "oxide-cli"}

      json(conn, 200, %{"device_code" => "device-code"})
    end)

    assert {:ok, %{"device_code" => "device-code"}} =
             Operation.request(client, :device_auth_request,
               request_body: [client_id: "oxide-cli"]
             )
  end

  test "raises when operation request body is required but missing", %{client: client} do
    assert_raise ArgumentError, ~r/requires request body/, fn ->
      Operation.request(client, :timeseries_query, params: [project: "prod"])
    end
  end

  test "streams a paginated operation by operation id", %{bypass: bypass, client: client} do
    Bypass.expect(bypass, "GET", "/v1/projects", fn conn ->
      conn = Plug.Conn.fetch_query_params(conn)

      case conn.query_params["page_token"] do
        nil ->
          assert conn.query_params["limit"] == "1"
          json(conn, 200, %{"items" => [%{"name" => "one"}], "next_page" => "two"})

        "two" ->
          json(conn, 200, %{"items" => [%{"name" => "two"}], "next_page" => nil})
      end
    end)

    assert [%{"name" => "one"}, %{"name" => "two"}] =
             Operation.stream(client, :project_list, limit: 1)
             |> Enum.to_list()
  end

  test "streams a paginated operation with path params", %{bypass: bypass, client: client} do
    Bypass.expect_once(bypass, "GET", "/v1/instances/name%2Fwith%2Fslash/disks", fn conn ->
      json(conn, 200, %{"items" => [%{"name" => "disk"}], "next_page" => nil})
    end)

    assert [%{"name" => "disk"}] =
             OxideApi.stream(client, :instance_disk_list,
               path_params: [instance: "name/with/slash"]
             )
             |> Enum.to_list()
  end

  defp json(conn, status, body) do
    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.resp(status, Jason.encode!(body))
  end
end
