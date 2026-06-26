defmodule OxideApi.Oxql do
  @moduledoc """
  Convenience helpers for running OxQL timeseries queries.

  OxQL queries are sent as strings to the Oxide timeseries query endpoints.
  Pass `:project` to `query/3` for project-scoped data, or omit it to run the
  fleet/system scoped endpoint.
  """

  alias OxideApi.{Client, Error, Result}
  alias OxideApi.Oxql.{Point, Series, Table}

  @type query_result :: map()
  @type tagged_result :: {:ok, query_result()} | {:error, Result.category(), term()}

  @doc """
  Runs an OxQL query.

  When `:project` is present, the project-scoped endpoint is used:

      OxideApi.Oxql.query(client, "get virtual_disk:bytes_read", project: "prod")

  Without `:project`, the system endpoint is used:

      OxideApi.Oxql.query(client, "get sled_cpu:usage")
  """
  @spec query(Client.t(), String.t(), keyword()) :: Client.result()
  def query(%Client{} = client, query, opts \\ []) do
    case Keyword.pop(opts, :project) do
      {nil, opts} -> system_query(client, query, opts)
      {project, opts} -> project_query(client, project, query, opts)
    end
  end

  @doc """
  Runs an OxQL query and raises on failure.

  This is useful in scripts where a failed query should stop execution.
  """
  @spec query!(Client.t(), String.t(), keyword()) :: query_result()
  def query!(%Client{} = client, query, opts \\ []) do
    client
    |> query(query, opts)
    |> Result.unwrap!()
  end

  @doc """
  Runs an OxQL query and tags errors with `OxideApi.Result.category/1`.

  Successful queries return `{:ok, result}`. Failures return
  `{:error, category, reason}`, where category is one of the values documented
  by `OxideApi.Result`.
  """
  @spec tagged_query(Client.t(), String.t(), keyword()) :: tagged_result()
  def tagged_query(%Client{} = client, query, opts \\ []) do
    client
    |> query(query, opts)
    |> Result.tagged()
  end

  @doc """
  Runs an OxQL query and returns only result tables.
  """
  @spec fetch_tables(Client.t(), String.t(), keyword()) :: {:ok, [map()]} | {:error, term()}
  def fetch_tables(%Client{} = client, query, opts \\ []) do
    case query(client, query, opts) do
      {:ok, result} -> {:ok, tables(result)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Runs an OxQL query and returns every timeseries across every result table.
  """
  @spec fetch_timeseries(Client.t(), String.t(), keyword()) :: {:ok, [map()]} | {:error, term()}
  def fetch_timeseries(%Client{} = client, query, opts \\ []) do
    case query(client, query, opts) do
      {:ok, result} -> {:ok, timeseries(result)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Runs an OxQL query and returns shaped timeseries structs.
  """
  @spec fetch_series(Client.t(), String.t(), keyword()) :: {:ok, [Series.t()]} | {:error, term()}
  def fetch_series(%Client{} = client, query, opts \\ []) do
    case query(client, query, opts) do
      {:ok, result} -> {:ok, series(result)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Runs an OxQL query and returns flattened sample points.
  """
  @spec fetch_points(Client.t(), String.t(), keyword()) :: {:ok, [Point.t()]} | {:error, term()}
  def fetch_points(%Client{} = client, query, opts \\ []) do
    case query(client, query, opts) do
      {:ok, result} -> {:ok, points(result)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Runs a project-scoped OxQL query.
  """
  @spec project_query(Client.t(), String.t(), String.t(), keyword()) :: Client.result()
  def project_query(%Client{} = client, project, query, opts \\ []) do
    with {:ok, body} <- query_body(query),
         {:ok, project} <- required_string(project, "project") do
      params =
        opts
        |> Keyword.get(:params, [])
        |> put_param(:project, project)

      Client.post(client, "/v1/timeseries/query", body,
        params: params,
        headers: Keyword.get(opts, :headers, []),
        req_options: Keyword.get(opts, :req_options, [])
      )
    end
  end

  @doc """
  Runs a fleet/system-scoped OxQL query.
  """
  @spec system_query(Client.t(), String.t(), keyword()) :: Client.result()
  def system_query(%Client{} = client, query, opts \\ []) do
    with {:ok, body} <- query_body(query) do
      Client.post(client, "/v1/system/timeseries/query", body,
        headers: Keyword.get(opts, :headers, []),
        req_options: Keyword.get(opts, :req_options, [])
      )
    end
  end

  @doc """
  Returns the tables from a successful OxQL response map.
  """
  @spec tables(query_result()) :: [map()]
  def tables(%{"tables" => tables}) when is_list(tables), do: tables
  def tables(%{tables: tables}) when is_list(tables), do: tables
  def tables(_result), do: []

  @doc """
  Flattens all timeseries entries across every table in an OxQL response.
  """
  @spec timeseries(query_result()) :: [map()]
  def timeseries(result) do
    result
    |> tables()
    |> Enum.flat_map(fn
      %{"timeseries" => timeseries} when is_list(timeseries) -> timeseries
      %{timeseries: timeseries} when is_list(timeseries) -> timeseries
      _table -> []
    end)
  end

  @doc """
  Shapes a raw OxQL response into table structs.

  The raw `tables/1` and `timeseries/1` helpers remain useful when callers want
  the API response as-is. Use `shape/1`, `series/1`, or `points/1` when you want
  field values and samples prepared for application code.
  """
  @spec shape(query_result()) :: [Table.t()]
  def shape(result) do
    result
    |> tables()
    |> Enum.map(&shape_table/1)
  end

  @doc """
  Returns every shaped timeseries across every table in an OxQL response.
  """
  @spec series(query_result()) :: [Series.t()]
  def series(result) do
    result
    |> shape()
    |> Enum.flat_map(& &1.timeseries)
  end

  @doc """
  Returns flattened sample points across every OxQL table and timeseries.
  """
  @spec points(query_result()) :: [Point.t()]
  def points(result) do
    result
    |> series()
    |> Enum.flat_map(& &1.points)
  end

  @doc """
  Returns true when an OxQL response contains no timeseries entries.
  """
  @spec empty?(query_result()) :: boolean()
  def empty?(result), do: timeseries(result) == []

  defp query_body(query) when is_binary(query) do
    if String.trim(query) == "" do
      {:error, Error.config("missing required OxQL query")}
    else
      {:ok, %{"query" => query}}
    end
  end

  defp query_body(_query), do: {:error, Error.config("missing required OxQL query")}

  defp required_string(value, name) when is_binary(value) do
    if String.trim(value) == "" do
      {:error, Error.config("missing required :#{name} option")}
    else
      {:ok, value}
    end
  end

  defp required_string(_value, name),
    do: {:error, Error.config("missing required :#{name} option")}

  defp put_param(params, key, value) when is_map(params), do: Map.put(params, key, value)

  defp put_param(params, key, value) when is_list(params) do
    params
    |> List.keydelete(key, 0)
    |> List.keydelete(to_string(key), 0)
    |> Keyword.put(key, value)
  end

  defp shape_table(table) do
    name = fetch_key(table, "name")

    timeseries =
      table
      |> table_timeseries()
      |> Enum.map(&shape_series(&1, name))

    %Table{name: name, timeseries: timeseries, raw: table}
  end

  defp table_timeseries(%{"timeseries" => timeseries}) when is_list(timeseries), do: timeseries
  defp table_timeseries(%{timeseries: timeseries}) when is_list(timeseries), do: timeseries
  defp table_timeseries(_table), do: []

  defp shape_series(raw_series, table) do
    fields =
      raw_series
      |> series_fields()
      |> unwrap_fields()

    %Series{
      table: table,
      fields: fields,
      points: shape_points(raw_series, table, fields),
      raw: raw_series
    }
  end

  defp series_fields(%{"fields" => fields}) when is_map(fields), do: fields
  defp series_fields(%{fields: fields}) when is_map(fields), do: fields
  defp series_fields(_series), do: %{}

  defp unwrap_fields(fields) do
    Map.new(fields, fn {key, value} ->
      {to_string(key), unwrap_field_value(value)}
    end)
  end

  defp unwrap_field_value(%{"value" => value}), do: value
  defp unwrap_field_value(%{value: value}), do: value
  defp unwrap_field_value(value), do: value

  defp shape_points(raw_series, table, fields) do
    points = series_points(raw_series)
    timestamps = fetch_key(points, "timestamps") |> list_or_empty()
    start_times = fetch_key(points, "start_times") |> list_or_empty()
    value_groups = fetch_key(points, "values") |> list_or_empty()

    timestamps
    |> Enum.with_index()
    |> Enum.flat_map(&points_at(&1, value_groups, table, fields, start_times))
  end

  defp points_at({timestamp, index}, value_groups, table, fields, start_times) do
    Enum.flat_map(value_groups, fn value_group ->
      point_at(value_group, index, timestamp, table, fields, start_times)
    end)
  end

  defp point_at(value_group, index, timestamp, table, fields, start_times) do
    case value_at(value_group, index) do
      {:ok, value} ->
        [
          %Point{
            table: table,
            fields: fields,
            timestamp: timestamp,
            start_time: list_at(start_times, index),
            metric_type: metric_type(value_group),
            value_type: value_type(value_group),
            value: value,
            raw: value_group
          }
        ]

      :error ->
        []
    end
  end

  defp series_points(%{"points" => points}) when is_map(points), do: points
  defp series_points(%{points: points}) when is_map(points), do: points
  defp series_points(_series), do: %{}

  defp value_at(value_group, index) do
    values = values(value_group)

    if index < length(values) do
      {:ok, Enum.at(values, index)}
    else
      :error
    end
  end

  defp values(value_group) do
    case fetch_key(value_group, "values") do
      %{} = value_array ->
        value_array
        |> fetch_key("values")
        |> list_or_empty()

      values when is_list(values) ->
        values

      _other ->
        []
    end
  end

  defp metric_type(value_group), do: fetch_key(value_group, "metric_type")

  defp value_type(value_group) do
    case fetch_key(value_group, "values") do
      %{} = value_array -> fetch_key(value_array, "type")
      _other -> fetch_key(value_group, "type")
    end
  end

  defp fetch_key(map, key) when is_map(map) do
    case Map.fetch(map, key) do
      {:ok, value} -> value
      :error -> Map.get(map, String.to_atom(key))
    end
  end

  defp fetch_key(_term, _key), do: nil

  defp list_or_empty(value) when is_list(value), do: value
  defp list_or_empty(_value), do: []

  defp list_at(list, index) when index < length(list), do: Enum.at(list, index)
  defp list_at(_list, _index), do: nil
end
