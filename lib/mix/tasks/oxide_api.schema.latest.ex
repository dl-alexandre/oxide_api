defmodule Mix.Tasks.OxideApi.Schema.Latest do
  @moduledoc """
  Checks the latest Oxide OpenAPI schema available from the Oxide Rust SDK.

      mix oxide_api.schema.latest
      mix oxide_api.schema.latest --vendor
      mix oxide_api.schema.latest --tag v0.17.0+2026060800.0.0

  By default this task is a dry run: it resolves and validates the latest
  schema, compares it with the vendored schema, and prints a path/operation
  diff. It writes a vendored OpenAPI file only when `--vendor` is passed.
  """

  use Mix.Task

  @shortdoc "Checks the latest Oxide OpenAPI schema tag"

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    {opts, _argv, _invalid} =
      OptionParser.parse(args,
        strict: [
          openapi_path: :string,
          tag: :string,
          tags_url: :string,
          vendor: :boolean
        ]
      )

    latest =
      OxideApi.Schema.latest_openapi!(
        tag: opts[:tag],
        tags_url: opts[:tags_url] || OxideApi.Schema.default_tags_url()
      )

    current = OxideApi.Schema.fetch_inventory!(schema_urls: [])
    diff = OxideApi.Schema.diff_inventories(current, latest.inventory)

    report(current, latest, diff)

    if opts[:vendor] do
      path = opts[:openapi_path] || "priv/oxide_api/openapi/#{latest.version}.json"
      OxideApi.Schema.write_openapi!(latest.schema, path)
      Mix.shell().info("")
      Mix.shell().info("Wrote #{path}")
    else
      Mix.shell().info("")
      Mix.shell().info("Dry run only. Pass --vendor to write the validated schema.")
    end
  end

  defp report(current, latest, diff) do
    Mix.shell().info("Current schema version: #{current.version}")
    Mix.shell().info("Latest schema version:  #{latest.version}")
    Mix.shell().info("Latest SDK tag:         #{latest.tag}")
    Mix.shell().info("Latest schema URL:      #{latest.url}")
    Mix.shell().info("")

    Mix.shell().info(
      "Path diff: #{count(diff.paths.added)} added, #{count(diff.paths.removed)} removed"
    )

    print_list("Added paths", diff.paths.added)
    print_list("Removed paths", diff.paths.removed)
    Mix.shell().info("")

    Mix.shell().info(
      "Operation diff: #{count(diff.operations.added)} added, " <>
        "#{count(diff.operations.removed)} removed"
    )

    print_list("Added operations", diff.operations.added)
    print_list("Removed operations", diff.operations.removed)
  end

  defp print_list(_title, []), do: :ok

  defp print_list(title, values) do
    Mix.shell().info("")
    Mix.shell().info("#{title}:")

    values
    |> Enum.take(25)
    |> Enum.each(&Mix.shell().info("  #{&1}"))

    remaining = length(values) - 25

    if remaining > 0 do
      Mix.shell().info("  ... #{remaining} more")
    end
  end

  defp count(values), do: length(values)
end
