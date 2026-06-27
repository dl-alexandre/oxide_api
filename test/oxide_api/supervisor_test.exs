defmodule OxideApi.SupervisorTest do
  use ExUnit.Case, async: false

  alias OxideApi.{Client, ManagedClient, Projects}
  alias OxideApi.Supervisor, as: OxideSupervisor

  setup do
    suffix = System.unique_integer([:positive])
    registry = Module.concat(__MODULE__, "Registry#{suffix}")
    client_supervisor = Module.concat(__MODULE__, "ClientSupervisor#{suffix}")
    supervisor = Module.concat(__MODULE__, "Supervisor#{suffix}")

    {:ok, _pid} =
      start_supervised(
        {OxideSupervisor,
         name: supervisor, registry: registry, client_supervisor: client_supervisor}
      )

    {:ok, registry: registry, client_supervisor: client_supervisor}
  end

  test "starts and stops dynamically supervised clients", %{
    registry: registry,
    client_supervisor: client_supervisor
  } do
    assert {:ok, pid} =
             OxideSupervisor.start_client(:system,
               host: "https://rack.example.com",
               token: "oxide-token",
               registry: registry,
               client_supervisor: client_supervisor
             )

    assert Process.alive?(pid)

    assert {:ok, %Client{host: "https://rack.example.com", token: "oxide-token"}} =
             OxideSupervisor.client(:system, registry: registry)

    assert {:ok, %ManagedClient{id: :system, scope: nil}} =
             OxideSupervisor.info(:system, registry: registry)

    assert :ok =
             OxideSupervisor.stop_client(:system,
               registry: registry,
               client_supervisor: client_supervisor
             )

    assert {:error, :not_found} = OxideSupervisor.client(:system, registry: registry)
  end

  test "starts project and silo scoped clients", %{
    registry: registry,
    client_supervisor: client_supervisor
  } do
    assert {:ok, _pid} =
             OxideSupervisor.start_project_client("prod",
               host: "https://rack.example.com",
               token: "oxide-project-token",
               registry: registry,
               client_supervisor: client_supervisor
             )

    assert {:ok, _pid} =
             OxideSupervisor.start_silo_client("engineering",
               host: "https://rack.example.com",
               token: "oxide-silo-token",
               registry: registry,
               client_supervisor: client_supervisor
             )

    assert {:ok, {:project, "prod"}} =
             OxideSupervisor.scope({:project, "prod"}, registry: registry)

    assert {:ok, {:silo, "engineering"}} =
             OxideSupervisor.scope({:silo, "engineering"}, registry: registry)
  end

  test "supervised clients can be used for API requests", %{
    registry: registry,
    client_supervisor: client_supervisor
  } do
    bypass = Bypass.open()

    assert {:ok, _pid} =
             OxideSupervisor.start_project_client("prod",
               host: "http://localhost:#{bypass.port}",
               token: "oxide-project-token",
               req_options: [retry: false],
               registry: registry,
               client_supervisor: client_supervisor
             )

    Bypass.expect_once(bypass, "GET", "/v1/projects", fn conn ->
      json(conn, 200, %{"items" => [%{"name" => "prod"}], "next_page" => nil})
    end)

    assert {:ok, client} = OxideSupervisor.client({:project, "prod"}, registry: registry)
    assert {:ok, %{"items" => [%{"name" => "prod"}]}} = Projects.list(client)
  end

  test "supports direct child specs for long-running clients" do
    assert {:ok, pid} =
             start_supervised(
               {ManagedClient,
                id: :system, host: "https://rack.example.com", token: "oxide-token"}
             )

    assert %Client{host: "https://rack.example.com", token: "oxide-token"} =
             ManagedClient.client(pid)
  end

  test "starts initial clients with the supervisor tree" do
    suffix = System.unique_integer([:positive])
    registry = Module.concat(__MODULE__, "InitialRegistry#{suffix}")
    client_supervisor = Module.concat(__MODULE__, "InitialClientSupervisor#{suffix}")
    supervisor = Module.concat(__MODULE__, "InitialSupervisor#{suffix}")

    {:ok, _pid} =
      start_supervised(
        {OxideSupervisor,
         name: supervisor,
         registry: registry,
         client_supervisor: client_supervisor,
         clients: [
           system: [
             host: "https://rack.example.com",
             token: "oxide-token"
           ]
         ]}
      )

    assert {:ok, %Client{host: "https://rack.example.com", token: "oxide-token"}} =
             OxideSupervisor.client(:system, registry: registry)
  end

  defp json(conn, status, body) do
    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.resp(status, Jason.encode!(body))
  end
end
