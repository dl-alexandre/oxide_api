# Run from this repository with:
#
#   OXIDE_HOST=https://rack.example.com OXIDE_TOKEN=... OXIDE_PROJECT=prod \
#     mix run examples/oxql_query.exs

query = System.get_env("OXIDE_OXQL_QUERY") || "get virtual_disk:bytes_read"
project = System.get_env("OXIDE_PROJECT")

opts =
  if project && String.trim(project) != "" do
    [project: project]
  else
    []
  end

{:ok, oxide} = OxideApi.new()

case OxideApi.Oxql.tagged_query(oxide, query, opts) do
  {:ok, result} ->
    result
    |> OxideApi.Oxql.tables()
    |> Enum.each(fn table ->
      count = table |> Map.get("timeseries", []) |> length()
      IO.puts("#{table["name"]}: #{count} timeseries")
    end)

  {:error, category, %OxideApi.Error{} = error} when category in [:rate_limited, :retryable] ->
    IO.puts("Retryable OxQL error: #{Exception.message(error)}")
    System.halt(75)

  {:error, category, %OxideApi.Error{} = error} ->
    IO.puts("OxQL #{category}: #{Exception.message(error)}")
    System.halt(1)

  {:error, :transport_error, reason} ->
    IO.puts("Transport error: #{inspect(reason)}")
    System.halt(75)

  {:error, category, reason} ->
    IO.puts("OxQL #{category}: #{inspect(reason)}")
    System.halt(1)
end
