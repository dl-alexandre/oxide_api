# OxideApi

[![CI](https://github.com/dl-alexandre/oxide_api/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/dl-alexandre/oxide_api/actions/workflows/ci.yml)

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

## Supervised Clients

For OTP applications, start the Oxide supervision tree and create clients
dynamically by application boundary:

```elixir
children = [
  {OxideApi.Supervisor, []}
]
```

```elixir
{:ok, _pid} =
  OxideApi.start_project_client("prod",
    host: "https://my-oxide-rack.com",
    token: "oxide-abc123"
  )

{:ok, oxide} = OxideApi.fetch_client({:project, "prod"})
{:ok, page} = OxideApi.list_instances(oxide, project: "prod")
```

Use `start_client/2` for arbitrary IDs, `start_project_client/2` for
project-scoped lifecycle, and `start_silo_client/2` for silo-scoped lifecycle.
Each managed client is a supervised process registered by ID; fetching the
client returns the immutable `%OxideApi.Client{}` so concurrent API calls run in
the caller process rather than being serialized through the manager.

Applications with more than one Oxide supervision tree should provide explicit
names:

```elixir
children = [
  {OxideApi.Supervisor,
   name: MyApp.OxideSupervisor,
   registry: MyApp.OxideRegistry,
   client_supervisor: MyApp.OxideClientSupervisor}
]
```

Then pass the same `:registry` and `:client_supervisor` options when starting or
fetching dynamic clients.

For a single named long-running client, use `OxideApi.ManagedClient` directly in
your supervision tree:

```elixir
children = [
  {OxideApi.ManagedClient,
   id: :system,
   name: MyApp.OxideClient,
   host: "https://my-oxide-rack.com",
   token: "oxide-abc123"}
]

oxide = OxideApi.ManagedClient.client(MyApp.OxideClient)
```

## Telemetry

The client emits `:telemetry` events for requests, retries, workflows, waits,
and cache activity:

```elixir
:telemetry.attach_many(
  "oxide-api-logger",
  [
    [:oxide_api, :request, :stop],
    [:oxide_api, :request, :retry],
    [:oxide_api, :workflow, :stop],
    [:oxide_api, :wait, :state_change],
    [:oxide_api, :cache, :hit],
    [:oxide_api, :cache, :miss]
  ],
  fn event, measurements, metadata, _config ->
    Logger.info("oxide event=#{inspect(event)} metadata=#{inspect(metadata)}")
  end,
  nil
)
```

Request stop metadata includes `:method`, `:path`, `:host`, `:result`, and, when
available, `:status`, `:request_id`, `:error_code`, and `:error_category`.
Durations are emitted in native time units.

## Read-Through Cache

Start a cache when read-heavy workflows need short-lived reuse:

```elixir
children = [
  {OxideApi.Cache, name: MyApp.OxideCache, table: MyApp.OxideCache}
]

{:ok, projects} =
  OxideApi.Cache.fetch(MyApp.OxideCache, {:projects, "prod"}, 30_000, fn ->
    OxideApi.fetch_all(oxide, :project_list)
  end)
```

The cache is explicit and ETS-backed. Callers choose keys and TTLs; writes and
mutating workflow helpers do not invalidate cache entries automatically.
Use `OxideApi.Cache.namespace/1`, `OxideApi.Cache.key/2`, and
`OxideApi.Cache.invalidate_namespace/2` when a workflow needs to expire a group
of related read-through entries after a write.

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

Update a project:

```elixir
{:ok, project} =
  OxideApi.update_project(oxide, "demo", %{
    "name" => "demo",
    "description" => "Updated demo project"
  })
```

Delete a project:

```elixir
{:ok, nil} = OxideApi.delete_project(oxide, "demo")
```

Delete endpoints that return HTTP 204 or 205 normalize the response body to
`nil`.

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

For long-running state transitions, use `OxideApi.Wait`:

```elixir
{:ok, instance} =
  OxideApi.wait_instance_running(oxide, "web",
    project: "prod",
    interval: 1_000,
    timeout: 120_000
  )
```

The generic wait helpers accept any fetch function:

```elixir
fetch = fn -> OxideApi.Instances.get(oxide, "web", project: "prod") end

OxideApi.Wait.changes(fetch, "run_state", interval: 1_000)
|> Enum.each(fn {previous, current, instance} ->
  IO.inspect({previous, current, instance["name"]})
end)
```

Use `OxideApi.wait_until_change/3` or `OxideApi.Wait.until_change/3` when a
long-polling task only needs the first observed state change.

Pass `:on_change` for callback-style coordination, or `:pubsub` and `:topic` to
broadcast state changes through `Phoenix.PubSub` when Phoenix is available.

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

Generated operation metadata also includes request/response shape names and
parameters, which is useful for agents or code generation:

```elixir
OxideApi.Operation.request_schema(:instance_create)
#=> "InstanceCreate"

OxideApi.Operation.response_schema(:instance_create)
#=> "Instance"

OxideApi.Operation.query_parameters(:timeseries_query)
#=> [%{name: "project", in: "query", required: true, schema: "NameOrId"}]
```

For endpoint coverage, the library uses two layers. Common resources and
workflows get handwritten helpers with clearer names and examples. The full
schema inventory remains reachable through operation IDs for long-tail
endpoints:

```elixir
{:ok, instance} =
  OxideApi.Operation.request(
    oxide,
    :instance_view,
    path_params: [instance: "web"],
    params: [project: "prod"]
  )
```

For body-bearing requests, pass `request_body:` and the generated
`request_content_type` decides whether the body is sent as JSON, form data, or
raw bytes:

```elixir
{:ok, result} =
  OxideApi.request_operation(
    oxide,
    :timeseries_query,
    params: [project: "prod"],
    request_body: %{"query" => "get virtual_disk:bytes_read"}
  )
```

## OxQL Timeseries Queries

Oxide timeseries queries are written in OxQL. Use
`OxideApi.Oxql.fetch_points/3` with `project: "name"` when you want samples
shaped for LiveView streams, charts, or agent loops:

```elixir
{:ok, points} =
  OxideApi.Oxql.fetch_points(
    oxide,
    "get virtual_disk:bytes_read",
    project: "prod"
  )

Enum.each(points, fn point ->
  IO.inspect({point.table, point.fields, point.timestamp, point.value})
end)
```

The shaping layer also exposes `shape/1` and `series/1`, returning
`%OxideApi.Oxql.Table{}` and `%OxideApi.Oxql.Series{}` structs while preserving
raw response data on each struct. `fetch_timeseries/3`, `tables/1`, and
`timeseries/1` remain available when you want the API response maps directly.

Omit `:project` to use the fleet/system-scoped endpoint:

```elixir
{:ok, result} = OxideApi.Oxql.query(oxide, "get sled_cpu:usage")

if OxideApi.Oxql.empty?(result) do
  Logger.info("OxQL query returned no timeseries")
end
```

For scripts, use `query!/3` to unwrap or raise:

```elixir
result = OxideApi.Oxql.query!(oxide, "get sled_cpu:usage")
tables = OxideApi.Oxql.tables(result)
```

For agent loops, use `tagged_query/3` to combine OxQL with
`OxideApi.Result` error categories:

```elixir
case OxideApi.Oxql.tagged_query(oxide, "get sled_cpu:usage") do
  {:ok, result} ->
    {:ok, OxideApi.Oxql.points(result)}

  {:error, category, error} when category in [:rate_limited, :retryable] ->
    {:retry, error}

  {:error, :transport_error, reason} ->
    {:retry_transport, reason}

  {:error, _category, error} ->
    {:error, error}
end
```

You can list available timeseries schemas through the system endpoint:

```elixir
{:ok, schemas} = OxideApi.System.Timeseries.schemas(oxide, limit: 100)
```

There is also a runnable example in `examples/oxql_query.exs`:

```sh
OXIDE_HOST=https://rack.example.com OXIDE_TOKEN=... OXIDE_PROJECT=prod \
  mix run examples/oxql_query.exs
```

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

Ensure a disk or instance exists:

```elixir
{:ok, disk} =
  OxideApi.Workflows.ensure_disk(oxide, "prod",
    name: "data",
    size: 21_474_836_480
  )

{:ok, instance} =
  OxideApi.Workflows.ensure_instance(oxide, "prod",
    name: "web",
    hostname: "web-1",
    ncpus: 2,
    memory: 4_294_967_296
  )
```

Ensure image, floating-IP, and firewall-rule state:

```elixir
{:ok, image} =
  OxideApi.Workflows.ensure_image_from_snapshot(
    oxide,
    "prod",
    "ubuntu-24-04",
    "b6f0f51b-1a7e-4f12-9057-3e16c8f7b68d",
    os: "ubuntu",
    version: "24.04"
  )

{:ok, floating_ip} =
  OxideApi.Workflows.ensure_floating_ip(oxide, "prod", name: "web-public")

{:ok, firewall_rules} =
  OxideApi.Workflows.ensure_vpc_firewall_rules(oxide, "prod", "app", [rule])
```

Workflow helpers are thin sequential composition functions, not transactions.
They stop at the first `{:error, reason}` and return that error without
attempting rollback. The `ensure_*` helpers first try to fetch existing
resources and create only when Oxide reports not-found, so they are safe to
rerun after a partial failure. `ensure_vpc_and_subnet/4`, for example, can
leave a newly-created VPC behind if subnet creation fails; rerunning the helper
will reuse that VPC and try the subnet again. Helpers that map to one Oxide API
call, such as `create_instance_with_disk/4` and `create_image_from_snapshot/5`,
leave cleanup semantics to the API.

You can use the underlying builders directly when you need to control the
request body yourself:

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

## Background Jobs

`OxideApi.Job` provides Oban-friendly helpers for common async work. Add Oban to
the host application when you want real workers:

```elixir
def deps do
  [
    {:oxide_api, "~> 0.0.1"},
    {:oban, "~> 2.23"}
  ]
end
```

Workers store IDs and JSON-safe maps, not client structs. Start a supervised
client with a JSON-safe ID, then enqueue jobs:

```elixir
{:ok, _pid} =
  OxideApi.start_project_client("prod",
    host: "https://my-oxide-rack.com",
    token: "oxide-abc123"
  )

changeset =
  OxideApi.Job.provision_instance(%{
    client_id: "prod",
    project: "prod",
    instance: %{name: "web", hostname: "web-1", ncpus: 2, memory: 4_294_967_296},
    disk: %{name: "boot", size: 21_474_836_480},
    wait_until: "running",
    interval: 1_000,
    timeout: 120_000
  })

Oban.insert(changeset)
```

Available workers cover instance provisioning, waiting for instance state, and
generated operation-ID requests. `OxideApi.Job.bulk/3` builds batches of Oban
changesets for bulk insertion. The convenience bulk builders
`provision_instances/4`, `wait_for_instances/5`, and `request_operations/3`
share common client/project arguments across many jobs:

```elixir
jobs =
  OxideApi.Job.wait_for_instances(
    "prod",
    "prod",
    ["web-1", "web-2"],
    "running",
    interval: 1_000,
    timeout: 120_000
  )

Oban.insert_all(jobs)
```

## Ash Integration

The optional Ash layer exposes data-layer-less resources for common Oxide
objects. Add Ash in the host application to use the declarative domain:

```elixir
def deps do
  [
    {:oxide_api, "~> 0.0.1"},
    {:ash, "~> 3.29"}
  ]
end
```

```elixir
{:ok, projects} = OxideApi.Ash.Domain.list_projects(oxide)
{:ok, instance} = OxideApi.Ash.Domain.get_instance(oxide, "prod", "web")
```

The resource modules also provide `from_api/1` mappers, so API maps can be
converted into `%OxideApi.Ash.Project{}`, `%OxideApi.Ash.Instance{}`, and
`%OxideApi.Ash.Disk{}`, `%OxideApi.Ash.Image{}`, and
`%OxideApi.Ash.FloatingIp{}` structs even in non-Ash applications.

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

For automatic retries, configure the underlying `Req` retry step when building
the client. `retryable?/1` works on normalized `%OxideApi.Error{}` structs after
the client receives an HTTP response, while `Req` retry callbacks see raw
`%Req.Response{}` and transport exception structs before the response is
normalized:

```elixir
retry = fn
  _request, %Req.Response{} = response ->
    %{status: status, body: body, headers: headers} = Req.Response.to_map(response)

    status
    |> OxideApi.Error.from_http(body, headers)
    |> OxideApi.Error.retryable?()

  _request, %Req.TransportError{} ->
    true

  _request, _other ->
    false
end

{:ok, oxide} =
  OxideApi.new(
    retry: retry,
    max_retries: 4,
    retry_delay: fn attempt -> trunc(:math.pow(2, attempt) * 500) end,
    retry_log_level: :info
  )
```

For rate limits, leaving `retry_delay` unset allows `Req` to honor
`retry-after` on 429/503 responses when Oxide sends it. Set `retry_delay` when
you want your own backoff or jitter policy.

For structured logs, use `to_log_metadata/1`:

```elixir
Logger.warning("Oxide request failed", OxideApi.Error.to_log_metadata(error))
```

For agent loops, `OxideApi.Result` classifies standard result tuples without
losing the original error:

```elixir
case OxideApi.Result.tagged(OxideApi.get_project(oxide, "prod")) do
  {:ok, project} ->
    {:ok, project}

  {:error, :not_found, _error} ->
    OxideApi.Workflows.ensure_project(oxide, "prod")

  {:error, category, error} when category in [:rate_limited, :retryable] ->
    {:retry, error}

  {:error, :transport_error, reason} ->
    {:retry_transport, reason}

  {:error, _category, error} ->
    {:error, error}
end
```

Use `OxideApi.Result.unwrap!/1` in scripts when raising on failure is preferred,
or `OxideApi.Result.value/2` when an error should collapse to a default.

## Schema Coverage

The project vendors the Oxide OpenAPI schema at
`priv/oxide_api/openapi/2026060800.0.0.json` and keeps a generated endpoint
inventory in `priv/oxide_api/endpoints.json`. The generated inventory includes
path/operation coverage data plus per-operation parameters, request body schema,
response status, and response body schema. Refresh the inventory and check local
path and operation coverage with:

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

CI also runs a no-optional-dependency matrix that compiles and tests without
Ash or Oban, so the core SDK stays usable in lightweight applications.

Optional checks:

```sh
mix credo --strict
mix dialyzer
```

Live integration tests are skipped unless `OXIDE_HOST` and `OXIDE_TOKEN` are
set.

## Examples

The `examples/` directory contains small runnable scripts:

- `examples/device_auth.exs` - device authorization, token polling, and token
  storage.
- `examples/common_workflows.exs` - project/VPC/subnet workflow helpers.
- `examples/oxql_query.exs` - project or system OxQL query execution.
- `examples/supervised_clients.exs` - dynamic per-project supervised clients.
- `examples/wait_for_instance.exs` - long-polling and change callbacks.
- `examples/oban_jobs.exs` - background job changesets for Oban.
- `examples/ash_resources.exs` - Ash domain and resource mapping.
