defmodule OxideApi.Wait do
  @moduledoc """
  Polling and state-change helpers for long-running Oxide operations.

  The generic functions accept a zero-arity fetch function returning
  `{:ok, resource}` or `{:error, reason}`. Convenience helpers layer Oxide
  resource semantics on top, such as waiting for an instance `run_state`.
  """

  alias OxideApi.{Client, Instances, Telemetry}

  @default_interval 1_000
  @default_timeout 60_000

  @type fetch_fun :: (-> Client.result())
  @type predicate :: (term() -> boolean())
  @type state_path :: atom() | String.t() | [atom() | String.t()]

  @doc """
  Polls `fetch_fun` until `predicate` returns true.

  Options:

    * `:interval` - delay between polls in milliseconds, defaults to `1000`
    * `:timeout` - maximum wait in milliseconds or `:infinity`, defaults to
      `60000`
    * `:metadata` - telemetry metadata merged into wait events
    * `:on_poll` - one-arity callback invoked for every successful poll
    * `:on_change` - three-arity callback invoked as `(previous, current, resource)`
      whenever `:state_path` changes
    * `:state_path` - path used for change detection
    * `:pubsub` and `:topic` - broadcast state changes through `Phoenix.PubSub`
    * `:message` - three-arity function that builds the PubSub message
  """
  @spec until(fetch_fun(), predicate(), keyword()) :: {:ok, term()} | {:error, term()}
  def until(fetch_fun, predicate, opts \\ [])
      when is_function(fetch_fun, 0) and is_function(predicate, 1) do
    started_at = System.monotonic_time(:millisecond)
    do_until(fetch_fun, predicate, opts, started_at, :oxide_initial)
  end

  @doc """
  Polls `fetch_fun` until a value at `path` matches `desired`.

  `desired` can be a single value or a list of acceptable values. Atom and string
  states compare by their string values.
  """
  @spec until_state(fetch_fun(), state_path(), term() | [term()], keyword()) ::
          {:ok, term()} | {:error, term()}
  def until_state(fetch_fun, path, desired, opts \\ []) when is_function(fetch_fun, 0) do
    desired = List.wrap(desired)
    opts = Keyword.put_new(opts, :state_path, path)

    until(fetch_fun, &state_in?(&1, path, desired), opts)
  end

  @doc """
  Polls until the value at `path` changes from its initial value.
  """
  @spec until_change(fetch_fun(), state_path(), keyword()) :: {:ok, term()} | {:error, term()}
  def until_change(fetch_fun, path, opts \\ []) when is_function(fetch_fun, 0) do
    opts = Keyword.put_new(opts, :state_path, path)
    metadata = wait_metadata(opts)

    with {:ok, initial} <- poll(fetch_fun, metadata) do
      initial_state = state_value(initial, path)
      started_at = System.monotonic_time(:millisecond)

      do_until(
        fetch_fun,
        fn resource -> !equivalent_state?(state_value(resource, path), initial_state) end,
        opts,
        started_at,
        initial_state
      )
    end
  end

  @doc """
  Returns an infinite lazy stream of poll results.

  The stream raises when `fetch_fun` returns `{:error, reason}`. Use
  `until/3` or `until_state/4` when errors should remain tagged tuples.
  """
  @spec stream(fetch_fun(), keyword()) :: Enumerable.t()
  def stream(fetch_fun, opts \\ []) when is_function(fetch_fun, 0) do
    interval = Keyword.get(opts, :interval, @default_interval)
    metadata = wait_metadata(opts)

    Stream.resource(
      fn -> :first end,
      fn state ->
        if state == :next and interval > 0 do
          Process.sleep(interval)
        end

        case poll(fetch_fun, metadata) do
          {:ok, resource} -> {[resource], :next}
          {:error, reason} -> raise "Oxide wait stream failed: #{inspect(reason)}"
        end
      end,
      fn _state -> :ok end
    )
  end

  @doc """
  Returns a stream that emits `{previous_state, current_state, resource}` only
  when the value at `path` changes.
  """
  @spec changes(fetch_fun(), state_path(), keyword()) :: Enumerable.t()
  def changes(fetch_fun, path, opts \\ []) when is_function(fetch_fun, 0) do
    fetch_fun
    |> stream(Keyword.put_new(opts, :state_path, path))
    |> Stream.transform(:oxide_initial, fn resource, previous ->
      current = state_value(resource, path)

      if previous == :oxide_initial or equivalent_state?(previous, current) do
        {[], current}
      else
        {[{previous, current, resource}], current}
      end
    end)
  end

  @doc """
  Waits for an instance to reach `desired_state`.
  """
  @spec instance_state(Client.t(), String.t(), term() | [term()], keyword()) ::
          {:ok, term()} | {:error, term()}
  def instance_state(%Client{} = client, instance, desired_state, opts \\ []) do
    {wait_opts, params} = split_wait_opts(opts)
    fetch_fun = fn -> Instances.get(client, instance, params) end

    wait_opts =
      wait_opts
      |> Keyword.put_new(:state_path, "run_state")
      |> Keyword.update(:metadata, %{resource: :instance, instance: instance}, fn metadata ->
        Map.merge(%{resource: :instance, instance: instance}, Map.new(metadata))
      end)

    until_state(fetch_fun, "run_state", desired_state, wait_opts)
  end

  @doc "Waits for an instance to reach `running`."
  @spec instance_running(Client.t(), String.t(), keyword()) :: {:ok, term()} | {:error, term()}
  def instance_running(%Client{} = client, instance, opts \\ []) do
    instance_state(client, instance, "running", opts)
  end

  @doc "Waits for an instance to reach `stopped`."
  @spec instance_stopped(Client.t(), String.t(), keyword()) :: {:ok, term()} | {:error, term()}
  def instance_stopped(%Client{} = client, instance, opts \\ []) do
    instance_state(client, instance, "stopped", opts)
  end

  @doc """
  Broadcasts a change message through Phoenix.PubSub when available.
  """
  @spec broadcast_change(term(), String.t(), term()) ::
          :ok | {:error, :phoenix_pubsub_not_loaded}
  def broadcast_change(pubsub, topic, message) do
    case Code.ensure_loaded(Module.concat(Phoenix, PubSub)) do
      {:module, pubsub_module} -> pubsub_module.broadcast(pubsub, topic, message)
      {:error, _reason} -> {:error, :phoenix_pubsub_not_loaded}
    end
  end

  defp do_until(fetch_fun, predicate, opts, started_at, previous_state) do
    timeout = Keyword.get(opts, :timeout, @default_timeout)
    interval = Keyword.get(opts, :interval, @default_interval)
    metadata = wait_metadata(opts)

    case poll(fetch_fun, metadata) do
      {:ok, resource} ->
        continue_until(resource, fetch_fun, predicate, opts, %{
          interval: interval,
          metadata: metadata,
          previous_state: previous_state,
          started_at: started_at,
          timeout: timeout
        })

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp continue_until(resource, fetch_fun, predicate, opts, context) do
    current_state = maybe_state_value(resource, opts)

    with :ok <- notify_poll(resource, opts),
         :ok <- notify_change(context.previous_state, current_state, resource, opts) do
      next_wait_step(
        resource,
        fetch_fun,
        predicate,
        opts,
        Map.put(context, :current_state, current_state)
      )
    end
  end

  defp next_wait_step(resource, fetch_fun, predicate, opts, context) do
    cond do
      predicate.(resource) ->
        {:ok, resource}

      timed_out?(context.started_at, context.timeout) ->
        emit_timeout(context)

      true ->
        sleep(context.interval)
        do_until(fetch_fun, predicate, opts, context.started_at, context.current_state)
    end
  end

  defp emit_timeout(context) do
    Telemetry.execute(
      [:oxide_api, :wait, :timeout],
      %{duration: elapsed(context.started_at)},
      Map.merge(context.metadata, %{state: context.current_state})
    )

    {:error, :timeout}
  end

  defp sleep(interval) when interval > 0, do: Process.sleep(interval)
  defp sleep(_interval), do: :ok

  defp poll(fetch_fun, metadata) do
    Telemetry.span([:oxide_api, :wait, :poll], metadata, fetch_fun)
  end

  defp notify_poll(resource, opts) do
    case Keyword.get(opts, :on_poll) do
      nil -> :ok
      fun when is_function(fun, 1) -> fun.(resource)
    end
  end

  defp notify_change(:oxide_initial, _current_state, _resource, _opts), do: :ok

  defp notify_change(previous_state, current_state, resource, opts) do
    if equivalent_state?(previous_state, current_state) do
      :ok
    else
      Telemetry.execute(
        [:oxide_api, :wait, :state_change],
        %{},
        wait_metadata(opts)
        |> Map.put(:previous_state, previous_state)
        |> Map.put(:current_state, current_state)
      )

      with :ok <- call_on_change(previous_state, current_state, resource, opts) do
        maybe_broadcast_change(previous_state, current_state, resource, opts)
      end
    end
  end

  defp call_on_change(previous_state, current_state, resource, opts) do
    case Keyword.get(opts, :on_change) do
      nil -> :ok
      fun when is_function(fun, 3) -> fun.(previous_state, current_state, resource)
    end
  end

  defp maybe_broadcast_change(previous_state, current_state, resource, opts) do
    with {:ok, pubsub} <- fetch_optional(opts, :pubsub),
         {:ok, topic} <- fetch_optional(opts, :topic) do
      message =
        case Keyword.get(opts, :message) do
          fun when is_function(fun, 3) ->
            fun.(previous_state, current_state, resource)

          _other ->
            {:oxide_api, :state_change, previous_state, current_state, resource}
        end

      broadcast_change(pubsub, topic, message)
    else
      :error -> :ok
    end
  end

  defp fetch_optional(opts, key) do
    case Keyword.fetch(opts, key) do
      {:ok, value} -> {:ok, value}
      :error -> :error
    end
  end

  defp state_in?(resource, path, desired) do
    state = state_value(resource, path)
    Enum.any?(desired, &equivalent_state?(state, &1))
  end

  defp maybe_state_value(resource, opts) do
    case Keyword.get(opts, :state_path) do
      nil -> nil
      path -> state_value(resource, path)
    end
  end

  defp state_value(resource, path) when is_list(path) do
    Enum.reduce(path, resource, fn
      _key, nil -> nil
      key, value -> map_value(value, key)
    end)
  end

  defp state_value(resource, path), do: state_value(resource, [path])

  defp map_value(%{} = map, key) do
    Map.get(map, key) || Map.get(map, to_string(key))
  end

  defp map_value(_value, _key), do: nil

  defp equivalent_state?(left, right), do: normalize_state(left) == normalize_state(right)

  defp normalize_state(value) when is_atom(value), do: Atom.to_string(value)
  defp normalize_state(value), do: to_string(value)

  defp timed_out?(_started_at, :infinity), do: false
  defp timed_out?(started_at, timeout), do: elapsed(started_at) >= timeout

  defp elapsed(started_at), do: System.monotonic_time(:millisecond) - started_at

  defp wait_metadata(opts) do
    opts
    |> Keyword.get(:metadata, %{})
    |> Map.new()
  end

  @wait_option_keys [
    :interval,
    :message,
    :metadata,
    :on_change,
    :on_poll,
    :pubsub,
    :state_path,
    :timeout,
    :topic
  ]

  defp split_wait_opts(opts), do: Keyword.split(opts, @wait_option_keys)
end
