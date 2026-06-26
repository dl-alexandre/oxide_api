defmodule OxideApi.OxqlTest do
  use ExUnit.Case, async: false

  alias OxideApi.{Client, Error, Oxql, Timeseries}

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

  test "runs project-scoped OxQL queries", %{bypass: bypass, client: client} do
    Bypass.expect_once(bypass, "POST", "/v1/timeseries/query", fn conn ->
      conn = Plug.Conn.fetch_query_params(conn)
      assert conn.query_params["project"] == "prod"

      {:ok, body, conn} = Plug.Conn.read_body(conn)
      assert Jason.decode!(body) == %{"query" => "get virtual_disk:bytes_read"}

      json(conn, 200, oxql_result())
    end)

    assert {:ok, result} =
             Oxql.query(client, "get virtual_disk:bytes_read", project: "prod")

    assert [%{"name" => "virtual_disk:bytes_read"}] = Oxql.tables(result)
    refute Oxql.empty?(result)
  end

  test "runs system OxQL queries through the root delegate", %{bypass: bypass, client: client} do
    Bypass.expect_once(bypass, "POST", "/v1/system/timeseries/query", fn conn ->
      assert conn.query_string == ""

      {:ok, body, conn} = Plug.Conn.read_body(conn)
      assert Jason.decode!(body) == %{"query" => "get sled_cpu:usage"}

      json(conn, 200, %{"tables" => []})
    end)

    assert {:ok, result} = OxideApi.query_oxql(client, "get sled_cpu:usage")
    assert Oxql.empty?(result)
  end

  test "can unwrap OxQL queries in scripts", %{bypass: bypass, client: client} do
    Bypass.expect_once(bypass, "POST", "/v1/system/timeseries/query", fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      assert Jason.decode!(body) == %{"query" => "get sled_cpu:usage"}

      json(conn, 200, %{"tables" => []})
    end)

    assert %{"tables" => []} = Oxql.query!(client, "get sled_cpu:usage")
  end

  test "can tag OxQL errors for agent loops", %{bypass: bypass, client: client} do
    Bypass.expect_once(bypass, "POST", "/v1/system/timeseries/query", fn conn ->
      json(conn, 503, %{"message" => "service unavailable"})
    end)

    assert {:error, :retryable, %Error{status: 503}} =
             Oxql.tagged_query(client, "get sled_cpu:usage")
  end

  test "can fetch tables and timeseries directly", %{bypass: bypass, client: client} do
    Bypass.expect_once(bypass, "POST", "/v1/timeseries/query", fn conn ->
      conn = Plug.Conn.fetch_query_params(conn)
      assert conn.query_params["project"] == "prod"

      json(conn, 200, oxql_result())
    end)

    assert {:ok, [%{"name" => "virtual_disk:bytes_read"}]} =
             Oxql.fetch_tables(client, "get virtual_disk:bytes_read", project: "prod")

    Bypass.expect_once(bypass, "POST", "/v1/timeseries/query", fn conn ->
      conn = Plug.Conn.fetch_query_params(conn)
      assert conn.query_params["project"] == "prod"

      json(conn, 200, oxql_result())
    end)

    assert {:ok, [%{"points" => %{"timestamps" => ["2026-06-26T16:00:00Z"]}}]} =
             Oxql.fetch_timeseries(client, "get virtual_disk:bytes_read", project: "prod")
  end

  test "flattens timeseries from result tables" do
    assert [
             %{"fields" => %{"disk" => %{"type" => "string", "value" => "disk-a"}}}
           ] = Oxql.timeseries(oxql_result())
  end

  test "validates query and project inputs", %{client: client} do
    assert {:error, %Error{message: "missing required OxQL query"}} =
             Oxql.query(client, "   ", project: "prod")

    assert {:error, %Error{message: "missing required :project option"}} =
             Oxql.project_query(client, "", "get virtual_disk:bytes_read")
  end

  test "low-level timeseries query accepts project params", %{bypass: bypass, client: client} do
    Bypass.expect_once(bypass, "POST", "/v1/timeseries/query", fn conn ->
      conn = Plug.Conn.fetch_query_params(conn)
      assert conn.query_params["project"] == "prod"

      {:ok, body, conn} = Plug.Conn.read_body(conn)
      assert Jason.decode!(body) == %{"query" => "get virtual_disk:bytes_read"}

      json(conn, 200, %{"tables" => []})
    end)

    assert {:ok, %{"tables" => []}} =
             Timeseries.query(client, %{"query" => "get virtual_disk:bytes_read"},
               project: "prod"
             )
  end

  defp oxql_result do
    %{
      "tables" => [
        %{
          "name" => "virtual_disk:bytes_read",
          "timeseries" => [
            %{
              "fields" => %{"disk" => %{"type" => "string", "value" => "disk-a"}},
              "points" => %{
                "timestamps" => ["2026-06-26T16:00:00Z"],
                "values" => [%{"type" => "i64", "values" => [42]}]
              }
            }
          ]
        }
      ]
    }
  end

  defp json(conn, status, body) do
    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.resp(status, Jason.encode!(body))
  end
end
