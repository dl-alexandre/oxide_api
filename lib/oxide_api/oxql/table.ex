defmodule OxideApi.Oxql.Table do
  @moduledoc """
  Structured OxQL table result.

  A table groups one or more timeseries with the same schema. The `:raw` field
  keeps the original response table for callers that still need schema details
  not promoted by the ergonomic shaping layer.
  """

  alias OxideApi.Oxql.Series

  @enforce_keys [:name, :timeseries]
  defstruct [:name, :timeseries, :raw]

  @type t :: %__MODULE__{
          name: String.t() | nil,
          timeseries: [Series.t()],
          raw: map() | nil
        }
end
