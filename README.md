# OxideApi

Elixir client for the [Oxide control plane API](https://docs.oxide.computer/api/guides/introduction).

This library currently targets Oxide API schema version `2026060800.0.0` and
sends that value in the `api-version` header on every request.

## Installation

Add `oxide_api` to your dependencies:

```elixir
def deps do
  [
    {:oxide_api, "~> 0.0.1"}
  ]
end
```

## Getting Started

Create a client with explicit credentials:

```elixir
{:ok, oxide} =
  OxideApi.new(
    host: "https://my-oxide-rack.com",
    token: "oxide-abc123"
  )
```

Or use the same environment variable names documented by Oxide:

```sh
export OXIDE_HOST=https://my-oxide-rack.com
export OXIDE_TOKEN=oxide-abc123
```

```elixir
{:ok, oxide} = OxideApi.new()
```

If the environment variables are not set, `OxideApi.new/1` also looks for the
Oxide CLI files in `$HOME/.config/oxide/config.toml` and
`$HOME/.config/oxide/credentials.toml`.

The token is sent as a bearer token. Device authorization endpoints are exposed
for clients that need to obtain a token before constructing the authenticated
client:

```elixir
{:ok, auth_client} =
  OxideApi.new_unauthenticated(host: "https://my-oxide-rack.com")

{:ok, auth} =
  OxideApi.Login.device_auth(auth_client, client_id: "oxide-cli")

{:ok, token} =
  OxideApi.Login.device_token(
    auth_client,
    client_id: "oxide-cli",
    device_code: auth["device_code"],
    grant_type: "urn:ietf:params:oauth:grant-type:device_code"
  )

{:ok, oxide} =
  OxideApi.new(
    host: "https://my-oxide-rack.com",
    token: token["access_token"]
  )
```

`new_unauthenticated/1` only omits the `authorization` header. It is intended
for auth bootstrap endpoints such as `/device/auth` and `/device/token`; normal
Oxide API calls should use `new/1` with a bearer token.

A simple end-to-end local token bootstrap can look like this:

```elixir
defmodule MyApp.OxideAuth do
  @token_path Path.expand("~/.config/my_app/oxide_token")

  def client(host) do
    token =
      case File.read(@token_path) do
        {:ok, token} -> String.trim(token)
        {:error, _reason} -> fetch_and_store_token(host)
      end

    OxideApi.new(host: host, token: token)
  end

  defp fetch_and_store_token(host) do
    {:ok, auth_client} = OxideApi.new_unauthenticated(host: host)
    {:ok, auth} = OxideApi.Login.device_auth(auth_client, client_id: "oxide-cli")

    IO.puts("Confirm code #{auth["user_code"]} in the Oxide web console.")

    {:ok, token} =
      OxideApi.Login.device_token(
        auth_client,
        client_id: "oxide-cli",
        device_code: auth["device_code"],
        grant_type: "urn:ietf:params:oauth:grant-type:device_code"
      )

    File.mkdir_p!(Path.dirname(@token_path))
    File.write!(@token_path, token["access_token"])
    token["access_token"]
  end
end
```

Request behavior can be tuned with `Req` options when the client is built:

```elixir
{:ok, oxide} =
  OxideApi.new(
    receive_timeout: 30_000,
    retry: :safe_transient,
    connect_options: [timeout: 5_000]
  )
```

## Basic Requests

List projects:

```elixir
{:ok, page} = OxideApi.list_projects(oxide, limit: 100)

Enum.each(page["items"], fn project ->
  IO.puts(project["name"])
end)
```

Create a project:

```elixir
{:ok, project} =
  OxideApi.create_project(oxide, %{
    "name" => "demo",
    "description" => "Demo project"
  })
```

Create a blank disk in a project:

```elixir
{:ok, disk} =
  OxideApi.create_disk(
    oxide,
    %{
      "name" => "data-disk",
      "description" => "blank disk for data storage",
      "size" => 21_474_836_480,
      "disk_backend" => %{
        "type" => "distributed",
        "disk_source" => %{
          "type" => "blank",
          "block_size" => 4096
        }
      }
    },
    project: "myproj"
  )
```

The same body can be built with the optional helpers:

```elixir
body = OxideApi.Builders.blank_disk("data-disk", 21_474_836_480)
{:ok, disk} = OxideApi.create_disk(oxide, body, project: "myproj")
```

Raw requests are also available while the higher-level surface grows:

```elixir
{:ok, body} = OxideApi.request(oxide, :get, "/v1/projects", params: [limit: 10])
```

Use `request_with_meta/4` when you need response headers or the status code:

```elixir
{:ok, response} = OxideApi.request_with_meta(oxide, :get, "/v1/ping")
response.status
```

## Streaming And Pagination

For paginated list endpoints, stream or fetch all items:

```elixir
OxideApi.stream_items(oxide, "/v1/projects", limit: 100)
|> Enum.each(&IO.puts(&1["name"]))

{:ok, projects} = OxideApi.fetch_all_items(oxide, "/v1/projects")
```

The generated inventory records which OpenAPI operations are paginated, so you
can stream by `operationId`:

```elixir
OxideApi.stream(oxide, :project_list, limit: 100)
|> Enum.each(&IO.puts(&1["name"]))

OxideApi.stream(oxide, :instance_disk_list,
  path_params: [instance: "web"],
  limit: 100
)
```

High-value resources expose direct stream helpers too:

```elixir
OxideApi.stream_projects(oxide, limit: 100)
OxideApi.stream_instances(oxide, project: "myproj")
OxideApi.stream_disks(oxide, project: "myproj")
```

Streams are lazy. API errors raise `%OxideApi.Error{}` while the stream is
being consumed, so wrap the consuming operation when you need to recover:

```elixir
try do
  OxideApi.stream(oxide, :instance_list, project: "prod", limit: 100)
  |> Stream.filter(&(&1["run_state"] == "running"))
  |> Enum.each(&IO.puts(&1["name"]))
rescue
  error in OxideApi.Error ->
    {:error, Exception.message(error)}
end
```

Query options such as `limit`, `sort_by`, and resource filters are passed
through as API query parameters. Retry and backoff behavior should be configured
on the client through `Req` options.

## Common Workflows

Create or reuse a project:

```elixir
{:ok, project} = OxideApi.Workflows.ensure_project(oxide, "prod")
```

Create a boot disk and instance in one API call:

```elixir
{:ok, instance} =
  OxideApi.Workflows.create_instance_with_disk(
    oxide,
    "prod",
    [name: "web", hostname: "web-1", ncpus: 2, memory: 4_294_967_296],
    [name: "boot", size: 21_474_836_480]
  )
```

Ensure a VPC and subnet exist before creating networked resources:

```elixir
{:ok, %{vpc: vpc, subnet: subnet}} =
  OxideApi.Workflows.ensure_vpc_and_subnet(
    oxide,
    "prod",
    "app",
    name: "frontend",
    ipv4_block: "10.0.0.0/24"
  )
```

Create an image from a snapshot:

```elixir
{:ok, image} =
  OxideApi.Workflows.create_image_from_snapshot(
    oxide,
    "prod",
    "ubuntu-24-04",
    "b6f0f51b-1a7e-4f12-9057-3e16c8f7b68d",
    os: "ubuntu",
    version: "24.04"
  )
```

The workflow helpers are thin composition functions. You can use the underlying
builders directly when you need to control the request body yourself:

```elixir
boot = OxideApi.Builders.create_disk_attachment("boot", 21_474_836_480)

body =
  OxideApi.Builders.instance("web", "web-1", 2, 4_294_967_296,
    boot_disk: boot,
    disks: [boot],
    external_ips: [OxideApi.Builders.ephemeral_ip()],
    network_interfaces: OxideApi.Builders.default_network_interfaces()
  )

{:ok, instance} = OxideApi.create_instance(oxide, body, project: "prod")
```

Build VPC, subnet, network-interface, floating-IP, and firewall bodies:

```elixir
vpc = OxideApi.Builders.vpc("app")
subnet = OxideApi.Builders.vpc_subnet("frontend", "10.0.0.0/24")
nic = OxideApi.Builders.network_interface("nic0", "app", "frontend")
floating_ip = OxideApi.Builders.floating_ip_create("web-public")

rule =
  OxideApi.Builders.firewall_rule("allow-https",
    targets: [OxideApi.Builders.firewall_target("instance", "web")],
    filters: OxideApi.Builders.firewall_filters(protocols: ["tcp"], ports: [%{"first" => 443}])
  )
```

All builders return plain maps, and every create/update wrapper still accepts a
raw map. That keeps new Oxide API fields usable before this library grows a
dedicated convenience helper.

## Error Handling

HTTP failures return `{:error, %OxideApi.Error{}}`. Transport failures return
`{:error, {:transport_error, reason}}`.

```elixir
case OxideApi.get_project(oxide, "missing") do
  {:ok, project} ->
    {:ok, project}

  {:error, %OxideApi.Error{} = error} ->
    cond do
      OxideApi.Error.not_found?(error) ->
        {:error, :missing}

      OxideApi.Error.retryable?(error) ->
        {:error, {:retry_later, OxideApi.Error.request_id(error)}}

      true ->
        {:error, Exception.message(error)}
    end

  {:error, {:transport_error, reason}} ->
    {:error, {:transport, reason}}
end
```

`retryable?/1` is intentionally small and predictable: it returns true for
request timeout, too-early, rate-limited, and 5xx responses. You can use it in
your own retry loop or as part of a retry policy:

```elixir
case OxideApi.Instances.start(oxide, "web", project: "prod") do
  {:ok, body} ->
    {:ok, body}

  {:error, %OxideApi.Error{} = error} ->
    if OxideApi.Error.retryable?(error) do
      {:retry, error}
    else
      {:error, error}
    end
end
```

For structured logs, use `to_log_metadata/1`:

```elixir
Logger.warning("Oxide request failed", OxideApi.Error.to_log_metadata(error))
```

## Schema Coverage

The project vendors the Oxide OpenAPI schema at
`priv/oxide_api/openapi/2026060800.0.0.json` and keeps a generated endpoint
inventory in `priv/oxide_api/endpoints.json`. Refresh the inventory and check
local path and operation coverage with:

```sh
mix oxide_api.schema --write
```

The task verifies the vendored schema's `info.version` matches this library's
`api-version` and fails if local path or operation coverage is incomplete.
Use `--allow-missing` for exploratory reports while adding new wrappers. When
intentionally updating to a new upstream schema tag, refresh the vendored
OpenAPI document first:

```sh
mix oxide_api.schema --refresh-openapi --write
```

To check the newest schema published by the Oxide Rust SDK before changing the
vendored file, run:

```sh
mix oxide_api.schema.latest
```

That task validates the latest schema and prints path/operation diffs as a dry
run. It writes a new vendored schema only with `--vendor`.

## Development

Run the standard local checks:

```sh
mix verify
```

Optional checks:

```sh
mix credo --strict
mix dialyzer
```

Live integration tests are skipped unless `OXIDE_HOST` and `OXIDE_TOKEN` are
set.
