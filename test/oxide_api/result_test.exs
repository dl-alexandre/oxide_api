defmodule OxideApi.ResultTest do
  use ExUnit.Case, async: true

  alias OxideApi.{Error, Result}

  test "classifies successful results" do
    result = {:ok, %{"name" => "demo"}}

    assert Result.ok?(result)
    refute Result.error?(result)
    assert Result.category(result) == :ok
    assert Result.value(result) == %{"name" => "demo"}
    assert Result.unwrap!(result) == %{"name" => "demo"}
    assert Result.tagged(result) == result
  end

  test "classifies not found errors" do
    error = Error.from_http(404, %{"message" => "missing", "error_code" => "not_found"})
    result = {:error, error}

    assert Result.error?(result)
    assert Result.not_found?(result)
    assert Result.category(result) == :not_found
    assert Result.tagged(result) == {:error, :not_found, error}
  end

  test "classifies retryable and rate-limited errors" do
    retryable = {:error, Error.from_http(503, %{"message" => "unavailable"})}
    rate_limited = {:error, Error.from_http(429, %{"message" => "slow down"})}

    assert Result.retryable?(retryable)
    assert Result.category(retryable) == :retryable

    assert Result.retryable?(rate_limited)
    assert Result.category(rate_limited) == :rate_limited
  end

  test "classifies permanent, configuration, and transport errors" do
    permanent = {:error, Error.from_http(422, %{"message" => "invalid"})}
    config = {:error, Error.config("missing required :token option")}
    transport = {:error, {:transport_error, :timeout}}

    assert Result.permanent_error?(permanent)
    assert Result.category(permanent) == :permanent_error

    assert Result.permanent_error?(config)
    assert Result.category(config) == :configuration_error

    assert Result.transport_error?(transport)
    assert Result.category(transport) == :transport_error
    refute Result.retryable?(transport)
  end

  test "returns defaults and raises on unwrap errors" do
    error = Error.from_http(500, %{"message" => "server unavailable"})

    assert Result.value({:error, error}, :default) == :default

    assert_raise Error, ~r/server unavailable/, fn ->
      Result.unwrap!({:error, error})
    end

    assert_raise RuntimeError, ~r/transport error/, fn ->
      Result.unwrap!({:error, {:transport_error, :timeout}})
    end
  end
end
