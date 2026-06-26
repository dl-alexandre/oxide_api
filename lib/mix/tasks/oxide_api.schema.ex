defmodule Mix.Tasks.OxideApi.Schema do
  @moduledoc """
  Syncs the Oxide API endpoint inventory and reports local coverage.

      mix oxide_api.schema
      mix oxide_api.schema --write
      mix oxide_api.schema --write --path priv/oxide_api/endpoints.json
      mix oxide_api.schema --refresh-openapi
      mix oxide_api.schema --allow-missing

  The task uses the vendored OpenAPI document by default. Use
  `--refresh-openapi` when intentionally updating the vendored schema from the
  upstream SDK tag. If the vendored schema is missing, the task tries known
  remote OpenAPI locations and finally falls back to the endpoint inventory
  embedded in the public Oxide API docs.
  """

  use Mix.Task

  @shortdoc "Checks Oxide API schema version and endpoint coverage"

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    {opts, _argv, _invalid} =
      OptionParser.parse(args,
        strict: [
          allow_missing: :boolean,
          openapi_path: :string,
          openapi_url: :string,
          path: :string,
          refresh_openapi: :boolean,
          write: :boolean
        ]
      )

    openapi_path = opts[:openapi_path] || OxideApi.Schema.default_openapi_path()

    if opts[:refresh_openapi] do
      path =
        OxideApi.Schema.refresh_openapi!(
          path: openapi_path,
          url: opts[:openapi_url] || OxideApi.Schema.default_openapi_url()
        )

      Mix.shell().info("Wrote #{path}")
    end

    inventory = OxideApi.Schema.fetch_inventory!(schema_path: openapi_path)
    expected_version = OxideApi.Client.api_version()

    if inventory.version != expected_version do
      Mix.raise("""
      Oxide API version mismatch.

      Expected: #{expected_version}
      Found:    #{inventory.version || "unknown"}
      Source:   #{inventory.source}
      """)
    end

    if opts[:write] do
      path = opts[:path] || OxideApi.Schema.default_artifact_path()
      OxideApi.Schema.write_inventory!(inventory, path)
      Mix.shell().info("Wrote #{path}")
    end

    path_coverage = OxideApi.Schema.coverage(inventory.paths)
    operation_coverage = OxideApi.Schema.operation_coverage(inventory.operations)

    report(inventory, path_coverage, operation_coverage)

    unless opts[:allow_missing] do
      ensure_complete_coverage!(path_coverage, operation_coverage)
    end
  end

  defp report(inventory, path_coverage, operation_coverage) do
    Mix.shell().info("Oxide API version: #{inventory.version}")
    Mix.shell().info("Schema source: #{inventory.source_type} (#{inventory.source})")
    Mix.shell().info("Endpoint paths: #{path_coverage.covered}/#{path_coverage.total} covered")
    Mix.shell().info("Path coverage: #{path_coverage.coverage_percent}%")

    if operation_coverage.total > 0 do
      Mix.shell().info(
        "Endpoint operations: #{operation_coverage.covered}/#{operation_coverage.total} covered"
      )

      Mix.shell().info("Operation coverage: #{operation_coverage.coverage_percent}%")
    end

    if path_coverage.missing != [] do
      Mix.shell().info("")
      Mix.shell().info("Missing endpoint paths:")

      path_coverage.missing
      |> Enum.take(25)
      |> Enum.each(&Mix.shell().info("  #{&1}"))

      remaining = length(path_coverage.missing) - 25

      if remaining > 0 do
        Mix.shell().info("  ... #{remaining} more")
      end
    end

    if operation_coverage.missing != [] do
      Mix.shell().info("")
      Mix.shell().info("Missing endpoint operations:")

      operation_coverage.missing
      |> Enum.take(25)
      |> Enum.each(&Mix.shell().info("  #{operation_label(&1)}"))

      remaining = length(operation_coverage.missing) - 25

      if remaining > 0 do
        Mix.shell().info("  ... #{remaining} more")
      end
    end
  end

  defp ensure_complete_coverage!(path_coverage, operation_coverage) do
    cond do
      path_coverage.missing != [] ->
        Mix.raise(
          "Oxide API path coverage is incomplete: " <>
            "#{path_coverage.covered}/#{path_coverage.total} covered"
        )

      operation_coverage.missing != [] ->
        Mix.raise(
          "Oxide API operation coverage is incomplete: " <>
            "#{operation_coverage.covered}/#{operation_coverage.total} covered"
        )

      true ->
        :ok
    end
  end

  defp operation_label(operation) do
    id =
      case operation.operation_id do
        nil -> ""
        operation_id -> " #{operation_id}"
      end

    "#{String.upcase(operation.method)} #{operation.path}#{id}"
  end
end
