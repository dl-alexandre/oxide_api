defmodule OxideApi.ClientTest do
  use ExUnit.Case, async: false

  alias OxideApi.{Client, Error, Login, Projects, Response}

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

  test "sends Oxide auth and version headers on GET requests", %{
    bypass: bypass,
    client: client
  } do
    Bypass.expect_once(bypass, "GET", "/v1/projects", fn conn ->
      headers = Map.new(conn.req_headers)

      assert headers["accept"] == "application/json"
      assert headers["authorization"] == "Bearer oxide-test-token"
      assert headers["api-version"] == Client.api_version()
      assert headers["user-agent"] =~ "oxide_api/"
      assert conn.query_string == "limit=10&sort_by=name_ascending"

      json(conn, 200, %{"items" => [], "next_page" => nil})
    end)

    assert {:ok, %{"items" => []}} =
             Projects.list(client, limit: 10, sort_by: "name_ascending")
  end

  test "encodes JSON bodies on POST requests", %{bypass: bypass, client: client} do
    Bypass.expect_once(bypass, "POST", "/v1/projects", fn conn ->
      assert conn.query_string == ""

      {:ok, body, conn} = Plug.Conn.read_body(conn)
      assert Jason.decode!(body) == %{"name" => "demo", "description" => "Demo project"}

      headers = Map.new(conn.req_headers)
      assert headers["content-type"] =~ "application/json"

      json(conn, 201, %{"id" => "project-id", "name" => "demo"})
    end)

    assert {:ok, %{"id" => "project-id"}} =
             Projects.create(client, %{"name" => "demo", "description" => "Demo project"})
  end

  test "encodes form bodies on raw requests", %{bypass: bypass, client: client} do
    Bypass.expect_once(bypass, "POST", "/device/token", fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      headers = Map.new(conn.req_headers)

      assert headers["content-type"] =~ "application/x-www-form-urlencoded"

      assert URI.decode_query(body) == %{
               "client_id" => "oxide-cli",
               "device_code" => "device-code",
               "grant_type" => "urn:ietf:params:oauth:grant-type:device_code"
             }

      json(conn, 200, %{"access_token" => "token"})
    end)

    assert {:ok, %{"access_token" => "token"}} =
             Login.device_token(
               client,
               client_id: "oxide-cli",
               device_code: "device-code",
               grant_type: "urn:ietf:params:oauth:grant-type:device_code"
             )
  end

  test "supports unauthenticated device token flows", %{bypass: bypass} do
    assert {:ok, client} =
             Client.new_unauthenticated(
               host: "http://localhost:#{bypass.port}",
               req_options: [retry: false]
             )

    Bypass.expect_once(bypass, "POST", "/device/auth", fn conn ->
      headers = Map.new(conn.req_headers)
      refute Map.has_key?(headers, "authorization")

      {:ok, body, conn} = Plug.Conn.read_body(conn)
      assert URI.decode_query(body) == %{"client_id" => "oxide-cli"}

      json(conn, 200, %{"device_code" => "device-code"})
    end)

    assert {:ok, %{"device_code" => "device-code"}} =
             Login.device_auth(client, client_id: "oxide-cli")
  end

  test "keeps Oxide error fields on API errors", %{bypass: bypass, client: client} do
    Bypass.expect_once(bypass, "GET", "/v1/projects/missing", fn conn ->
      json(conn, 404, %{
        "error_code" => "not_found",
        "message" => "project not found",
        "request_id" => "rq-123"
      })
    end)

    assert {:error,
            %Error{
              status: 404,
              message: "project not found",
              error_code: "not_found",
              request_id: "rq-123"
            } = error} = Projects.get(client, "missing")

    assert Error.not_found?(error)
    assert Error.request_id(error) == "rq-123"
    refute Error.retryable?(error)
    assert Exception.message(error) =~ "request_id: rq-123"
  end

  test "keeps request id from headers when error body omits it", %{bypass: bypass, client: client} do
    Bypass.expect_once(bypass, "GET", "/v1/projects", fn conn ->
      conn
      |> Plug.Conn.put_resp_header("x-request-id", "rq-header")
      |> json(503, %{"message" => "service unavailable"})
    end)

    assert {:error, %Error{} = error} = Projects.list(client)
    assert Error.retryable?(error)
    assert Error.server_error?(error)
    assert Error.request_id(error) == "rq-header"

    assert Error.to_log_metadata(error) == [
             oxide_status: 503,
             oxide_request_id: "rq-header",
             oxide_retryable: true
           ]

    assert Exception.message(error) =~ "status: 503"
  end

  test "returns transport errors", %{bypass: bypass, client: client} do
    Bypass.down(bypass)

    assert {:error, {:transport_error, _reason}} = Projects.list(client)
  end

  test "can return response metadata and normalizes 204 bodies", %{
    bypass: bypass,
    client: client
  } do
    Bypass.expect_once(bypass, "GET", "/v1/ping", fn conn ->
      conn
      |> Plug.Conn.put_resp_header("x-request-id", "rq-204")
      |> Plug.Conn.resp(204, "")
    end)

    assert {:ok, %Response{status: 204, body: nil} = response} =
             Client.request_with_meta(client, :get, "/v1/ping")

    assert Response.get_header(response, "x-request-id") == "rq-204"
  end

  test "escapes path segments", %{bypass: bypass, client: client} do
    Bypass.expect_once(bypass, "GET", "/v1/projects/name%2Fwith%2Fslash", fn conn ->
      json(conn, 200, %{"name" => "name/with/slash"})
    end)

    assert {:ok, %{"name" => "name/with/slash"}} = Projects.get(client, "name/with/slash")
  end

  test "can build a client from Oxide environment variables" do
    original_host = System.get_env("OXIDE_HOST")
    original_token = System.get_env("OXIDE_TOKEN")

    System.put_env("OXIDE_HOST", "https://rack.example.com/")
    System.put_env("OXIDE_TOKEN", "oxide-env-token")

    on_exit(fn ->
      restore_env("OXIDE_HOST", original_host)
      restore_env("OXIDE_TOKEN", original_token)
    end)

    assert {:ok,
            %Client{
              host: "https://rack.example.com",
              token: "oxide-env-token"
            }} = Client.new()
  end

  test "can build a client from Oxide CLI config files" do
    original_host = System.get_env("OXIDE_HOST")
    original_token = System.get_env("OXIDE_TOKEN")

    config_dir =
      Path.join(System.tmp_dir!(), "oxide-api-test-#{System.unique_integer([:positive])}")

    File.mkdir_p!(config_dir)
    File.write!(Path.join(config_dir, "config.toml"), ~s(host = "https://file.example.com/"\n))

    File.write!(
      Path.join(config_dir, "credentials.toml"),
      ~s([default]\ntoken = "oxide-file-token"\n)
    )

    System.delete_env("OXIDE_HOST")
    System.delete_env("OXIDE_TOKEN")

    on_exit(fn ->
      restore_env("OXIDE_HOST", original_host)
      restore_env("OXIDE_TOKEN", original_token)
      File.rm_rf!(config_dir)
    end)

    assert {:ok,
            %Client{
              host: "https://file.example.com",
              token: "oxide-file-token"
            }} = Client.new(config_dir: config_dir)
  end

  test "environment variables take precedence over CLI config files" do
    original_host = System.get_env("OXIDE_HOST")
    original_token = System.get_env("OXIDE_TOKEN")

    config_dir =
      Path.join(System.tmp_dir!(), "oxide-api-test-#{System.unique_integer([:positive])}")

    File.mkdir_p!(config_dir)
    File.write!(Path.join(config_dir, "config.toml"), ~s(host = "https://file.example.com/"\n))
    File.write!(Path.join(config_dir, "credentials.toml"), ~s(token = "oxide-file-token"\n))

    System.put_env("OXIDE_HOST", "https://env.example.com")
    System.put_env("OXIDE_TOKEN", "oxide-env-token")

    on_exit(fn ->
      restore_env("OXIDE_HOST", original_host)
      restore_env("OXIDE_TOKEN", original_token)
      File.rm_rf!(config_dir)
    end)

    assert {:ok,
            %Client{
              host: "https://env.example.com",
              token: "oxide-env-token"
            }} = Client.new(config_dir: config_dir)
  end

  test "exposes timeout and retry options on the client" do
    assert {:ok, %Client{req_options: req_options}} =
             Client.new(
               host: "https://rack.example.com",
               token: "oxide-token",
               retry: false,
               receive_timeout: 2_000,
               pool_timeout: 1_000,
               connect_options: [timeout: 500]
             )

    assert req_options[:retry] == false
    assert req_options[:receive_timeout] == 2_000
    assert req_options[:pool_timeout] == 1_000
    assert req_options[:connect_options] == [timeout: 500]
  end

  test "streams paginated items lazily", %{bypass: bypass, client: client} do
    Bypass.expect(bypass, "GET", "/v1/projects", fn conn ->
      conn = Plug.Conn.fetch_query_params(conn)

      case conn.query_params["page_token"] do
        nil ->
          json(conn, 200, %{
            "items" => [%{"name" => "one"}],
            "next_page" => "next-token"
          })

        "next-token" ->
          json(conn, 200, %{
            "items" => [%{"name" => "two"}],
            "next_page" => nil
          })
      end
    end)

    assert [%{"name" => "one"}, %{"name" => "two"}] =
             Client.stream_items(client, "/v1/projects", limit: 1)
             |> Enum.to_list()
  end

  test "raised stream errors include request IDs", %{bypass: bypass, client: client} do
    Bypass.expect_once(bypass, "GET", "/v1/projects", fn conn ->
      conn
      |> Plug.Conn.put_resp_header("x-request-id", "rq-stream")
      |> json(500, %{"message" => "server unavailable"})
    end)

    assert_raise Error, ~r/request_id: rq-stream/, fn ->
      client
      |> Client.stream_items("/v1/projects")
      |> Enum.to_list()
    end
  end

  test "can fetch all paginated items", %{bypass: bypass, client: client} do
    Bypass.expect(bypass, "GET", "/v1/projects", fn conn ->
      conn = Plug.Conn.fetch_query_params(conn)

      case conn.query_params["page_token"] do
        nil -> json(conn, 200, %{"items" => [1], "next_page" => "two"})
        "two" -> json(conn, 200, %{"items" => [2], "next_page" => nil})
      end
    end)

    assert {:ok, [1, 2]} = Client.fetch_all_items(client, "/v1/projects")
  end

  test "reports missing configuration" do
    original_host = System.get_env("OXIDE_HOST")
    original_token = System.get_env("OXIDE_TOKEN")

    System.delete_env("OXIDE_HOST")
    System.delete_env("OXIDE_TOKEN")

    on_exit(fn ->
      restore_env("OXIDE_HOST", original_host)
      restore_env("OXIDE_TOKEN", original_token)
    end)

    assert {:error,
            %Error{error_code: "configuration_error", message: "missing required :host option"}} =
             Client.new()
  end

  defp json(conn, status, body) do
    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.resp(status, Jason.encode!(body))
  end

  defp restore_env(name, nil), do: System.delete_env(name)
  defp restore_env(name, value), do: System.put_env(name, value)
end
