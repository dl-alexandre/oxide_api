defmodule OxideApi.Oxql.Point do
  @moduledoc """
  Flattened OxQL sample point.

  This shape is intended for LiveView streams, chart adapters, and agent loops:
  each struct represents one value from one timeseries at one timestamp.
  """

  @enforce_keys [:table, :fields, :timestamp, :metric_type, :value_type, :value]
  defstruct [
    :table,
    :fields,
    :timestamp,
    :start_time,
    :metric_type,
    :value_type,
    :value,
    :raw
  ]

  @type t :: %__MODULE__{
          table: String.t() | nil,
          fields: %{optional(String.t()) => term()},
          timestamp: String.t() | nil,
          start_time: String.t() | nil,
          metric_type: String.t() | nil,
          value_type: String.t() | nil,
          value: term(),
          raw: map() | nil
        }
end
