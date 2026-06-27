defmodule OxideApi.Ash do
  @moduledoc """
  Helpers shared by the optional Ash integration.

  When Ash is available, `OxideApi.Ash.Domain` exposes declarative resources for
  common Oxide objects. Without Ash, the resource modules still provide plain
  structs and `from_api/1` mapping helpers.
  """

  @doc """
  Returns true when Ash is available at compile/runtime.
  """
  @spec available?() :: boolean()
  def available?, do: Code.ensure_loaded?(Ash)

  @doc false
  @spec field(map(), atom() | String.t()) :: term()
  def field(map, key) when is_map(map) do
    Map.get(map, key) || Map.get(map, to_string(key))
  end

  @doc false
  @spec id_or_name(map()) :: String.t() | nil
  def id_or_name(map) when is_map(map), do: field(map, "id") || field(map, "name")
end
