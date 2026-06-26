# Changelog

## 0.0.1 - 2026-06-26

First Hex release candidate for the Oxide control plane API client.

### Oxide API Schema

- Targets Oxide API schema version `2026060800.0.0`.
- Vendors the OpenAPI document at `priv/oxide_api/openapi/2026060800.0.0.json`.
- Generates endpoint metadata at `priv/oxide_api/endpoints.json`.
- Release verification reports `218/218` endpoint paths and `315/315`
  operations covered.

### Added

- Core `Req`-based client with bearer auth, configurable timeouts/retries,
  `api-version` and `user-agent` headers, response metadata, 204/205 body
  normalization, and Oxide CLI credential-file loading.
- Structured `%OxideApi.Error{}` with request ID extraction, retry/not-found
  predicates, formatted exception messages, and log metadata helpers.
- `OxideApi.Result` helpers for classifying result tuples in agent loops.
- Full path and operation wrapper coverage for the vendored schema, including
  common user/project resources, system/admin APIs, and experimental support
  bundle/probe endpoints.
- Generated operation metadata for request body schemas, response schemas,
  response statuses, and path/query parameters.
- Metadata-driven `OxideApi.Operation.request/3` and
  `OxideApi.request_operation/3` helpers for operation-ID calls across the full
  endpoint inventory.
- Schema-derived pagination metadata plus path-based and operation-ID streaming
  helpers.
- First-class OxQL helpers for project and fleet/system timeseries queries,
  including bang/tagged query variants, direct table/timeseries fetch helpers,
  shaped `%OxideApi.Oxql.Table{}`, `%OxideApi.Oxql.Series{}`, and
  `%OxideApi.Oxql.Point{}` structs, result traversal helpers, and an example
  script.
- Plain-map builders for common project, disk, image, instance, VPC, subnet,
  floating IP, network interface, snapshot, and firewall request bodies.
- `OxideApi.Workflows` helpers for common project, instance, VPC/subnet, and
  image-from-snapshot workflows.
- `mix oxide_api.schema` and `mix oxide_api.schema.latest` release-maintenance
  tasks.
- CI, ExUnit tests, Credo, Dialyzer, ExDoc, package metadata, and gated live
  integration tests via `OXIDE_HOST` and `OXIDE_TOKEN`.
- Runnable examples for device auth, common workflows, and OxQL queries.

### Verification

- `mix oxide_api.schema.latest`
- `mix oxide_api.schema --write`
- `mix verify`
- `mix credo --strict`
- `mix dialyzer --format short`
- `mix docs`
- `mix hex.build`
- `mix hex.build --unpack`

### Known Limitations

- Request and response bodies are plain maps; this release does not generate
  structs or schema-derived Elixir types.
- Operation-ID requests are intentionally low-level and metadata-driven;
  handwritten helpers remain the preferred interface for common workflows.
- Live integration tests run only when `OXIDE_HOST` and `OXIDE_TOKEN` are set.
- Telemetry hooks are not included in this release.
