defmodule OxideApi.JobTest do
  use ExUnit.Case, async: false

  alias OxideApi.Job
  alias OxideApi.Supervisor, as: OxideSupervisor

  setup do
    original_registry = Application.get_env(:oxide_api, :job_registry)
    suffix = System.unique_integer([:positive])
    registry = Module.concat(__MODULE__, "Registry#{suffix}")
    client_supervisor = Module.concat(__MODULE__, "ClientSupervisor#{suffix}")
    supervisor = Module.concat(__MODULE__, "Supervisor#{suffix}")

    {:ok, _pid} =
      start_supervised(
        {OxideSupervisor,
         name: supervisor, registry: registry, client_supervisor: client_supervisor}
      )

    Application.put_env(:oxide_api, :job_registry, registry)

    on_exit(fn ->
      if original_registry do
        Application.put_env(:oxide_api, :job_registry, original_registry)
      else
        Application.delete_env(:oxide_api, :job_registry)
      end
    end)

    {:ok, registry: registry, client_supervisor: client_supervisor}
  end

  test "normalizes job args to string-keyed JSON-safe maps" do
    assert %{
             "client_id" => "prod",
             "instance" => %{"name" => "web", "tags" => ["blue", "green"]},
             "state" => "running"
           } =
             Job.normalize_args(
               client_id: :prod,
               instance: %{name: "web", tags: [:blue, :green]},
               state: :running
             )
  end

  test "builds bulk wait jobs" do
    jobs =
      Job.wait_for_instances("prod", "prod", ["web-1", "web-2"], "running",
        interval: 1_000,
        timeout: 120_000
      )

    assert length(jobs) == 2
  end

  test "performs wait-for-instance jobs with supervised clients", %{
    client_supervisor: client_supervisor,
    registry: registry
  } do
    bypass = Bypass.open()

    assert {:ok, _pid} =
             OxideSupervisor.start_client("prod",
               host: "http://localhost:#{bypass.port}",
               token: "oxide-test-token",
               req_options: [retry: false],
               registry: registry,
               client_supervisor: client_supervisor
             )

    counter = start_supervised!({Agent, fn -> 0 end})

    Bypass.expect(bypass, "GET", "/v1/instances/web", fn conn ->
      conn = Plug.Conn.fetch_query_params(conn)
      assert conn.query_params["project"] == "prod"

      state =
        Agent.get_and_update(counter, fn
          0 -> {"starting", 1}
          count -> {"running", count + 1}
        end)

      json(conn, 200, %{"name" => "web", "run_state" => state})
    end)

    assert :ok =
             Job.perform_wait_for_instance(%{
               "client_id" => "prod",
               "project" => "prod",
               "instance" => "web",
               "state" => "running",
               "interval" => 0,
               "timeout" => 100
             })
  end

  test "performs provision-instance jobs and waits when requested", %{
    client_supervisor: client_supervisor,
    registry: registry
  } do
    bypass = Bypass.open()

    assert {:ok, _pid} =
             OxideSupervisor.start_client("prod",
               host: "http://localhost:#{bypass.port}",
               token: "oxide-test-token",
               req_options: [retry: false],
               registry: registry,
               client_supervisor: client_supervisor
             )

    Bypass.expect_once(bypass, "POST", "/v1/instances", fn conn ->
      conn = Plug.Conn.fetch_query_params(conn)
      assert conn.query_params["project"] == "prod"
      assert %{"name" => "web", "boot_disk" => %{"name" => "boot"}} = read_json(conn)
      json(conn, 201, %{"name" => "web", "run_state" => "creating"})
    end)

    Bypass.expect_once(bypass, "GET", "/v1/instances/web", fn conn ->
      conn = Plug.Conn.fetch_query_params(conn)
      assert conn.query_params["project"] == "prod"
      json(conn, 200, %{"name" => "web", "run_state" => "running"})
    end)

    assert :ok =
             Job.perform_provision_instance(%{
               "client_id" => "prod",
               "project" => "prod",
               "instance" => %{
                 "name" => "web",
                 "hostname" => "web-1",
                 "ncpus" => 2,
                 "memory" => 4_294_967_296
               },
               "disk" => %{"name" => "boot", "size" => 21_474_836_480},
               "wait_until" => "running",
               "interval" => 0,
               "timeout" => 100
             })
  end

  test "converts permanent API errors into Oban cancellation" do
    assert {:cancel, message} =
             Job.to_oban_result({:error, OxideApi.Error.config("missing client")})

    assert message =~ "missing client"
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
