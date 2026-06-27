defmodule OxideApi.TelemetryTest do
  use ExUnit.Case, async: false

  alias OxideApi.{Client, Projects, Workflows}

  setup do
    handler_id = {__MODULE__, self(), System.unique_integer([:positive])}

    events = [
      [:oxide_api, :request, :start],
      [:oxide_api, :request, :stop],
      [:oxide_api, :request, :retry],
      [:oxide_api, :workflow, :start],
      [:oxide_api, :workflow, :stop],
      [:oxide_api, :workflow, :step, :start],
      [:oxide_api, :workflow, :step, :stop]
    ]

    :telemetry.attach_many(
      handler_id,
      events,
      &__MODULE__.handle_event/4,
      self()
    )

    on_exit(fn -> :telemetry.detach(handler_id) end)

    :ok
  end

  test "emits request start and stop events with error metadata" do
    bypass = Bypass.open()
    client = client!(bypass, retry: false)

    Bypass.expect_once(bypass, "GET", "/v1/projects/missing", fn conn ->
      json(conn, 404, %{"message" => "not found", "error_code" => "not_found"})
    end)

    assert {:error, %OxideApi.Error{}} = Projects.get(client, "missing")

    assert_receive {:telemetry, [:oxide_api, :request, :start], %{system_time: _},
                    %{method: :get, path: "/v1/projects/missing"}}

    assert_receive {:telemetry, [:oxide_api, :request, :stop], %{duration: duration},
                    %{
                      result: :error,
                      error_category: :not_found,
                      status: 404,
                      path: "/v1/projects/missing"
                    }}

    assert is_integer(duration)
  end

  test "emits retry events for retried requests" do
    bypass = Bypass.open()
    counter = start_supervised!({Agent, fn -> 0 end})

    client =
      client!(bypass,
        max_retries: 1,
        retry_delay: fn _attempt -> 0 end,
        retry_log_level: false
      )

    Bypass.expect(bypass, "GET", "/v1/projects", fn conn ->
      count = Agent.get_and_update(counter, &{&1, &1 + 1})

      if count == 0 do
        json(conn, 500, %{"message" => "server unavailable"})
      else
        json(conn, 200, %{"items" => [], "next_page" => nil})
      end
    end)

    assert {:ok, %{"items" => []}} = Projects.list(client)

    assert_receive {:telemetry, [:oxide_api, :request, :retry], %{attempt: 1},
                    %{status: 500, retries_left: 1, path: "/v1/projects"}}

    assert_receive {:telemetry, [:oxide_api, :request, :stop], %{duration: _},
                    %{result: :ok, status: 200, path: "/v1/projects"}}
  end

  test "emits workflow and workflow step events" do
    bypass = Bypass.open()
    client = client!(bypass, retry: false)

    Bypass.expect_once(bypass, "GET", "/v1/projects/demo", fn conn ->
      json(conn, 200, %{"name" => "demo"})
    end)

    assert {:ok, %{"name" => "demo"}} = Workflows.ensure_project(client, "demo")

    assert_receive {:telemetry, [:oxide_api, :workflow, :start], %{system_time: _},
                    %{workflow: :ensure_project}}

    assert_receive {:telemetry, [:oxide_api, :workflow, :step, :start], %{system_time: _},
                    %{resource: :project, step: :get}}

    assert_receive {:telemetry, [:oxide_api, :workflow, :step, :stop], %{duration: _},
                    %{resource: :project, step: :get, result: :ok}}

    assert_receive {:telemetry, [:oxide_api, :workflow, :stop], %{duration: _},
                    %{workflow: :ensure_project, result: :ok}}
  end

  defp client!(bypass, opts) do
    {:ok, client} =
      Client.new(
        Keyword.merge(
          [
            host: "http://localhost:#{bypass.port}",
            token: "oxide-test-token"
          ],
          opts
        )
      )

    client
  end

  defp json(conn, status, body) do
    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.resp(status, Jason.encode!(body))
  end

  def handle_event(event, measurements, metadata, test_pid) do
    send(test_pid, {:telemetry, event, measurements, metadata})
  end
end
