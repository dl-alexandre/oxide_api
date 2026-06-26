defmodule OxideApi.Oxql.Series do
  @moduledoc """
  Structured OxQL timeseries result.

  Field values are unwrapped from Oxide's typed field representation, so a raw
  field such as `%{"type" => "string", "value" => "disk-a"}` becomes
  `"disk-a"` in `:fields`.
  """

  alias OxideApi.Oxql.Point

  @enforce_keys [:table, :fields, :points]
  defstruct [:table, :fields, :points, :raw]

  @type t :: %__MODULE__{
          table: String.t() | nil,
          fields: %{optional(String.t()) => term()},
          points: [Point.t()],
          raw: map() | nil
        }
end
