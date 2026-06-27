defmodule OxideApi.Cache do
  @moduledoc """
  Small ETS-backed read-through cache for read-heavy Oxide workloads.

  The cache is explicit: callers choose keys, TTLs, and the function to run on a
  miss. This avoids hiding cache behavior inside mutating resource helpers.
  """

  use GenServer

  alias OxideApi.Telemetry

  @default_name __MODULE__
  @default_ttl 30_000

  @type table :: atom()
  @type cache_key :: term()
  @type fetch_fun :: (-> {:ok, term()} | {:error, term()})

  @doc """
  Starts a cache process that owns a named ETS table.
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, @default_name)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @impl GenServer
  def init(opts) do
    table = Keyword.get(opts, :table, Keyword.get(opts, :name, @default_name))

    ^table =
      :ets.new(table, [
        :named_table,
        :public,
        read_concurrency: true,
        write_concurrency: true
      ])

    {:ok, %{table: table}}
  end

  @doc """
  Fetches a cached value or stores the result of `fun`.
  """
  @spec fetch(table(), cache_key(), non_neg_integer(), fetch_fun()) ::
          {:ok, term()} | {:error, term()}
  def fetch(table \\ @default_name, key, ttl \\ @default_ttl, fun)
      when is_atom(table) and is_function(fun, 0) do
    case get(table, key) do
      {:ok, value} ->
        Telemetry.execute([:oxide_api, :cache, :hit], %{}, %{cache: table, key: key})
        {:ok, value}

      :miss ->
        Telemetry.execute([:oxide_api, :cache, :miss], %{}, %{cache: table, key: key})

        case fun.() do
          {:ok, value} ->
            put(table, key, value, ttl)
            {:ok, value}

          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  @doc """
  Builds a scoped cache key.
  """
  @spec key(term(), term()) :: {term(), term()}
  def key(scope, key), do: {scope, key}

  @doc """
  Builds a namespace tuple for scoped cache keys.
  """
  @spec namespace(term() | [term()]) :: tuple()
  def namespace(parts) when is_list(parts), do: List.to_tuple(parts)
  def namespace(part), do: {part}

  @doc """
  Reads a value from the cache.
  """
  @spec get(table(), cache_key()) :: {:ok, term()} | :miss
  def get(table \\ @default_name, key) when is_atom(table) do
    now = now_ms()

    case :ets.lookup(table, key) do
      [{^key, expires_at, value}] when expires_at > now ->
        {:ok, value}

      [{^key, _expires_at, _value}] ->
        delete(table, key)
        :miss

      [] ->
        :miss
    end
  rescue
    ArgumentError -> :miss
  end

  @doc """
  Stores a value with a TTL in milliseconds.
  """
  @spec put(table(), cache_key(), term(), non_neg_integer()) :: :ok
  def put(table \\ @default_name, key, value, ttl \\ @default_ttl)
      when is_atom(table) and is_integer(ttl) and ttl >= 0 do
    true = :ets.insert(table, {key, now_ms() + ttl, value})
    :ok
  end

  @doc """
  Deletes a cache key.
  """
  @spec delete(table(), cache_key()) :: :ok
  def delete(table \\ @default_name, key) when is_atom(table) do
    :ets.delete(table, key)
    :ok
  rescue
    ArgumentError -> :ok
  end

  @doc """
  Clears every entry from a cache table.
  """
  @spec clear(table()) :: :ok
  def clear(table \\ @default_name) when is_atom(table) do
    :ets.delete_all_objects(table)
    :ok
  rescue
    ArgumentError -> :ok
  end

  @doc """
  Invalidates keys that belong to `namespace`.

  Namespaces match tuple prefixes, so invalidating `{:project, "prod"}` removes
  keys such as `{{:project, "prod"}, :instances}` and
  `{:project, "prod", :instances}`.
  """
  @spec invalidate_namespace(table(), term()) :: :ok
  def invalidate_namespace(table \\ @default_name, namespace) when is_atom(table) do
    table
    |> :ets.tab2list()
    |> Enum.each(fn {key, _expires_at, _value} ->
      if namespaced?(key, namespace), do: :ets.delete(table, key)
    end)

    :ok
  rescue
    ArgumentError -> :ok
  end

  defp namespaced?({namespace, _key}, namespace), do: true

  defp namespaced?(key, namespace) when is_tuple(key) and is_tuple(namespace) do
    key
    |> Tuple.to_list()
    |> starts_with?(Tuple.to_list(namespace))
  end

  defp namespaced?(_key, _namespace), do: false

  defp starts_with?(_values, []), do: true
  defp starts_with?([value | values], [value | prefix]), do: starts_with?(values, prefix)
  defp starts_with?(_values, _prefix), do: false

  defp now_ms, do: System.monotonic_time(:millisecond)
end
