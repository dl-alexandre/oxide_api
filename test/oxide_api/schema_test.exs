defmodule OxideApi.SchemaTest do
  use ExUnit.Case, async: true

  alias OxideApi.Schema

  test "extracts endpoint paths from docs HTML" do
    html = """
    current version is `2026060800.0.0`
    "/device/auth"
    "/login/{silo_name}/saml/{provider_name}"
    "/v1/projects"
    "/v1/projects/{project}"
    "/v1/disks?project=myproj"
    "/experimental/v1/probes/{probe}\\"
    """

    assert Schema.extract_version(html) == "2026060800.0.0"

    assert Schema.extract_paths(html) == [
             "/device/auth",
             "/experimental/v1/probes/{probe}",
             "/login/{silo_name}/saml/{provider_name}",
             "/v1/disks",
             "/v1/projects",
             "/v1/projects/{project}"
           ]
  end

  test "loads the vendored OpenAPI schema inventory" do
    inventory = Schema.fetch_inventory!(schema_urls: [])

    assert inventory.source == Schema.default_openapi_path()
    assert inventory.source_type == "vendored_openapi"
    assert inventory.version == OxideApi.Client.api_version()
    assert "/device/auth" in inventory.paths

    assert Enum.any?(inventory.operations, fn operation ->
             operation.method == "post" and operation.path == "/device/auth" and
               operation.operation_id == "device_auth_request"
           end)

    assert Enum.any?(Schema.paginated_operations(inventory), fn operation ->
             operation.method == "get" and operation.path == "/v1/projects" and
               operation.operation_id == "project_list" and operation.item_schema == "Project"
           end)
  end

  test "reports coverage against local path list" do
    remote = [
      "/v1/projects",
      "/v1/projects/{project}",
      "/v1/disks"
    ]

    local = [
      "/v1/projects",
      "/v1/projects/{project}",
      "/v1/local-only"
    ]

    assert %{
             total: 3,
             covered: 2,
             coverage_percent: 66.67,
             missing: ["/v1/disks"],
             extra: ["/v1/local-only"]
           } = Schema.coverage(remote, local)
  end

  test "reports operation coverage against local method and path list" do
    remote = [
      %{method: "get", path: "/v1/projects", operation_id: "project_list"},
      %{method: "post", path: "/v1/projects", operation_id: "project_create"},
      %{method: "delete", path: "/v1/projects/{project}", operation_id: "project_delete"}
    ]

    local = [
      %{method: "get", path: "/v1/projects"},
      %{method: "delete", path: "/v1/local-only"}
    ]

    assert %{
             total: 3,
             covered: 1,
             coverage_percent: 33.33,
             missing: [
               %{
                 method: "delete",
                 path: "/v1/projects/{project}",
                 operation_id: "project_delete"
               },
               %{method: "post", path: "/v1/projects", operation_id: "project_create"}
             ],
             extra: [
               %{method: "delete", path: "/v1/local-only"}
             ]
           } = Schema.operation_coverage(remote, local)
  end

  test "builds OpenAPI raw URLs for SDK tags" do
    assert Schema.openapi_url_for_tag("v0.17.0+2026060800.0.0") ==
             "https://raw.githubusercontent.com/oxidecomputer/oxide.rs/v0.17.0%2B2026060800.0.0/oxide.json"
  end

  test "diffs inventories for schema maintenance reports" do
    current = %{
      paths: ["/v1/old", "/v1/shared"],
      operations: [
        %{method: "get", path: "/v1/old"},
        %{method: "get", path: "/v1/shared"}
      ]
    }

    latest = %{
      paths: ["/v1/new", "/v1/shared"],
      operations: [
        %{method: "get", path: "/v1/new"},
        %{method: "get", path: "/v1/shared"}
      ]
    }

    assert Schema.diff_inventories(current, latest) == %{
             paths: %{added: ["/v1/new"], removed: ["/v1/old"]},
             operations: %{added: ["GET /v1/new"], removed: ["GET /v1/old"]}
           }
  end

  test "detects local interpolated endpoint paths" do
    local_paths = Schema.local_paths()

    assert "/device/auth" in local_paths
    assert "/login/{silo_name}/saml/{provider_name}" in local_paths
    assert "/v1/projects" in local_paths
    assert "/v1/projects/{project}" in local_paths
    assert "/v1/instances/{instance}/start" in local_paths
  end

  test "detects local method and path operations" do
    local_operations = Schema.local_operations()

    assert %{method: "post", path: "/device/auth"} in local_operations
    assert %{method: "post", path: "/login/{silo_name}/saml/{provider_name}"} in local_operations
    assert %{method: "post", path: "/v1/logout"} in local_operations
  end
end
