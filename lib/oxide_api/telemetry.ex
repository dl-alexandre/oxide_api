defmodule OxideApi.Telemetry do
  @moduledoc """
  Telemetry helpers and event documentation for Oxide API requests and workflows.

  Emitted request events:

    * `[:oxide_api, :request, :start]`
    * `[:oxide_api, :request, :stop]`
    * `[:oxide_api, :request, :exception]`
    * `[:oxide_api, :request, :retry]`

  Emitted workflow events:

    * `[:oxide_api, :workflow, :start]`
    * `[:oxide_api, :workflow, :stop]`
    * `[:oxide_api, :workflow, :exception]`
    * `[:oxide_api, :workflow, :step, :start]`
    * `[:oxide_api, :workflow, :step, :stop]`
    * `[:oxide_api, :workflow, :step, :exception]`

  Emitted wait/poll events:

    * `[:oxide_api, :wait, :poll, :start]`
    * `[:oxide_api, :wait, :poll, :stop]`
    * `[:oxide_api, :wait, :poll, :exception]`
    * `[:oxide_api, :wait, :state_change]`
    * `[:oxide_api, :wait, :timeout]`

  Emitted cache events:

    * `[:oxide_api, :cache, :hit]`
    * `[:oxide_api, :cache, :miss]`

  Durations are reported in native time units. Convert with
  `System.convert_time_unit(duration, :native, unit)`.
  """

  alias OxideApi.{Error, Response, Result}

  @retry_statuses [408, 429, 500, 502, 503, 504]

  @doc false
  @spec request_metadata(OxideApi.Client.t(), atom(), String.t()) :: map()
  def request_metadata(client, method, path) do
    %{
      host: client.host,
      method: method,
      path: path
    }
  end

  @doc false
  @spec span([atom()], map(), (-> term())) :: term()
  def span(event_prefix, metadata, fun) when is_list(event_prefix) and is_function(fun, 0) do
    start_time = System.monotonic_time()
    start_metadata = Map.put_new(metadata, :telemetry_span_context, make_ref())

    execute(event_prefix ++ [:start], %{system_time: System.system_time()}, start_metadata)

    try do
      result = fun.()
      duration = System.monotonic_time() - start_time
      stop_metadata = Map.merge(start_metadata, result_metadata(result))

      execute(event_prefix ++ [:stop], %{duration: duration}, stop_metadata)

      result
    rescue
      exception ->
        duration = System.monotonic_time() - start_time
        metadata = exception_metadata(start_metadata, :error, exception, __STACKTRACE__)

        execute(event_prefix ++ [:exception], %{duration: duration}, metadata)

        reraise exception, __STACKTRACE__
    catch
      kind, reason ->
        duration = System.monotonic_time() - start_time
        metadata = exception_metadata(start_metadata, kind, reason, __STACKTRACE__)

        execute(event_prefix ++ [:exception], %{duration: duration}, metadata)

        :erlang.raise(kind, reason, __STACKTRACE__)
    end
  end

  @doc false
  @spec execute([atom()], map(), map()) :: :ok
  def execute(event_name, measurements, metadata) do
    :telemetry.execute(event_name, measurements, metadata)
  end

  @doc false
  @spec result_metadata(term()) :: map()
  def result_metadata({:ok, %Response{} = response}) do
    %{
      result: :ok,
      status: response.status,
      request_id: Response.get_header(response, "x-request-id")
    }
    |> reject_nil_values()
  end

  def result_metadata({:ok, _value}), do: %{result: :ok}

  def result_metadata({:error, %Error{} = error}) do
    %{
      result: :error,
      error: error,
      error_category: Result.category({:error, error}),
      status: error.status,
      error_code: error.error_code,
      request_id: error.request_id
    }
    |> reject_nil_values()
  end

  def result_metadata({:error, reason}) do
    %{
      result: :error,
      error: reason,
      error_category: Result.category({:error, reason})
    }
  end

  def result_metadata(_other), do: %{}

  @doc false
  @spec instrument_req_options(keyword(), map()) :: keyword()
  def instrument_req_options(req_options, metadata) do
    case Keyword.get(req_options, :retry, :safe_transient) do
      retry when retry in [false, nil] ->
        req_options

      retry ->
        Keyword.put(req_options, :retry, retry_fun(retry, metadata))
    end
  end

  defp retry_fun(:safe, metadata), do: retry_fun(:safe_transient, metadata)
  defp retry_fun(:never, _metadata), do: false

  defp retry_fun(:safe_transient, metadata) do
    fn request, response_or_exception ->
      decision =
        if safe_method?(request) do
          transient_decision(response_or_exception)
        else
          false
        end

      emit_retry(decision, request, response_or_exception, metadata)
      decision
    end
  end

  defp retry_fun(:transient, metadata) do
    fn request, response_or_exception ->
      decision = transient_decision(response_or_exception)
      emit_retry(decision, request, response_or_exception, metadata)
      decision
    end
  end

  defp retry_fun(fun, metadata) when is_function(fun, 2) do
    fn request, response_or_exception ->
      decision = fun.(request, response_or_exception)
      emit_retry(decision, request, response_or_exception, metadata)
      decision
    end
  end

  defp retry_fun(fun, metadata) when is_function(fun, 1) do
    fn request, response_or_exception ->
      decision = fun.(response_or_exception)
      emit_retry(decision, request, response_or_exception, metadata)
      decision
    end
  end

  defp retry_fun(other, _metadata), do: other

  defp emit_retry(decision, request, response_or_exception, metadata) do
    retry_count = Req.Request.get_private(request, :req_retry_count, 0)
    max_retries = Req.Request.get_option(request, :max_retries, 3)

    if retry_decision?(decision) and retry_count < max_retries do
      measurements =
        decision
        |> retry_measurements()
        |> Map.put(:attempt, retry_count + 1)

      retry_metadata =
        metadata
        |> Map.merge(retry_metadata(response_or_exception))
        |> Map.put(:max_retries, max_retries)
        |> Map.put(:retries_left, max_retries - retry_count)

      execute([:oxide_api, :request, :retry], measurements, retry_metadata)
    end

    :ok
  end

  defp retry_decision?(true), do: true
  defp retry_decision?({:delay, delay}) when is_integer(delay), do: true
  defp retry_decision?(_decision), do: false

  defp retry_measurements({:delay, delay}), do: %{delay: delay}
  defp retry_measurements(_decision), do: %{}

  defp retry_metadata(%Req.Response{status: status}) do
    %{status: status, reason: :http_status}
  end

  defp retry_metadata(%{__exception__: true} = exception) do
    %{reason: :exception, exception: exception}
  end

  defp retry_metadata(reason), do: %{reason: reason}

  defp transient_decision(%Req.Response{status: status}) when status in @retry_statuses, do: true
  defp transient_decision(%Req.Response{}), do: false
  defp transient_decision(%{__exception__: true}), do: true
  defp transient_decision({:error, _reason}), do: true
  defp transient_decision(_reason), do: false

  defp safe_method?(request) do
    request
    |> Req.Request.get_option(:method, :get)
    |> then(&(&1 in [:get, :head]))
  end

  defp exception_metadata(metadata, kind, reason, stacktrace) do
    metadata
    |> Map.put(:kind, kind)
    |> Map.put(:reason, reason)
    |> Map.put(:stacktrace, stacktrace)
  end

  defp reject_nil_values(map) do
    Map.reject(map, fn {_key, value} -> is_nil(value) end)
  end
end
