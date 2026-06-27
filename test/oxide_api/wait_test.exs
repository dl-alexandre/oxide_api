defmodule OxideApi.WaitTest do
  use ExUnit.Case, async: false

  alias OxideApi.{Client, Wait}

  test "waits until a fetched resource reaches a desired state" do
    test_pid = self()
    states = start_supervised!({Agent, fn -> ["starting", "running"] end})

    fetch = fn ->
      state =
        Agent.get_and_update(states, fn
          [state | rest] -> {state, rest}
          [] -> {"running", []}
        end)

      {:ok, %{"run_state" => state}}
    end

    assert {:ok, %{"run_state" => "running"}} =
             Wait.until_state(fetch, "run_state", "running",
               interval: 0,
               timeout: 100,
               on_change: fn previous, current, _resource ->
                 send(test_pid, {:changed, previous, current})
                 :ok
               end
             )

    assert_receive {:changed, "starting", "running"}
  end

  test "returns timeout when desired state is not reached" do
    fetch = fn -> {:ok, %{"run_state" => "starting"}} end

    assert {:error, :timeout} =
             Wait.until_state(fetch, "run_state", "running", interval: 0, timeout: 0)
  end

  test "streams state changes" do
    states = start_supervised!({Agent, fn -> ["starting", "starting", "running", "stopped"] end})

    fetch = fn ->
      state = Agent.get_and_update(states, fn [state | rest] -> {state, rest} end)
      {:ok, %{"run_state" => state}}
    end

    assert [
             {"starting", "running", %{"run_state" => "running"}},
             {"running", "stopped", %{"run_state" => "stopped"}}
           ] =
             fetch
             |> Wait.changes("run_state", interval: 0)
             |> Enum.take(2)
  end

  test "waits until state changes from the first poll" do
    states = start_supervised!({Agent, fn -> ["starting", "starting", "running"] end})

    fetch = fn ->
      state = Agent.get_and_update(states, fn [state | rest] -> {state, rest} end)
      {:ok, %{"run_state" => state}}
    end

    assert {:ok, %{"run_state" => "running"}} =
             Wait.until_change(fetch, "run_state", interval: 0, timeout: 100)
  end

  test "waits for an instance to become running" do
    bypass = Bypass.open()

    {:ok, client} =
      Client.new(
        host: "http://localhost:#{bypass.port}",
        token: "oxide-test-token",
        req_options: [retry: false]
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

    assert {:ok, %{"run_state" => "running"}} =
             Wait.instance_running(client, "web", project: "prod", interval: 0, timeout: 100)
  end

  defp json(conn, status, body) do
    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.resp(status, Jason.encode!(body))
  end
end
