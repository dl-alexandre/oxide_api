defmodule OxideApi.CacheTest do
  use ExUnit.Case, async: false

  alias OxideApi.Cache

  setup do
    table = Module.concat(__MODULE__, "Table#{System.unique_integer([:positive])}")
    start_supervised!({Cache, name: table, table: table})
    {:ok, table: table}
  end

  test "fetch stores successful values until ttl expires", %{table: table} do
    counter = start_supervised!({Agent, fn -> 0 end})

    fetch = fn ->
      value = Agent.get_and_update(counter, &{&1, &1 + 1})
      {:ok, value}
    end

    assert {:ok, 0} = Cache.fetch(table, :projects, 1_000, fetch)
    assert {:ok, 0} = Cache.fetch(table, :projects, 1_000, fetch)
    assert Agent.get(counter, & &1) == 1
  end

  test "expired entries miss", %{table: table} do
    assert :ok = Cache.put(table, :key, :value, 0)
    assert :miss = Cache.get(table, :key)
  end

  test "delete and clear remove entries", %{table: table} do
    Cache.put(table, :one, 1, 1_000)
    Cache.put(table, :two, 2, 1_000)

    assert :ok = Cache.delete(table, :one)
    assert :miss = Cache.get(table, :one)

    assert :ok = Cache.clear(table)
    assert :miss = Cache.get(table, :two)
  end

  test "invalidates namespaced entries", %{table: table} do
    namespace = Cache.namespace([:project, "prod"])

    Cache.put(table, Cache.key(namespace, :instances), [1], 1_000)
    Cache.put(table, {:project, "prod", :disks}, [2], 1_000)
    Cache.put(table, Cache.key({:project, "dev"}, :instances), [3], 1_000)

    assert :ok = Cache.invalidate_namespace(table, namespace)
    assert :miss = Cache.get(table, Cache.key(namespace, :instances))
    assert :miss = Cache.get(table, {:project, "prod", :disks})
    assert {:ok, [3]} = Cache.get(table, Cache.key({:project, "dev"}, :instances))
  end
end
