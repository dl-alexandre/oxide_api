defmodule OxideApi.IntegrationTest do
  use ExUnit.Case, async: false

  if System.get_env("OXIDE_HOST") && System.get_env("OXIDE_TOKEN") do
    test "can call the live Oxide ping endpoint" do
      assert {:ok, client} = OxideApi.new()
      assert {:ok, _body} = OxideApi.Ping.get(client)
    end
  else
    @tag skip: "set OXIDE_HOST and OXIDE_TOKEN to run live integration tests"
    test "live Oxide integration tests are configured" do
      :ok
    end
  end
end
