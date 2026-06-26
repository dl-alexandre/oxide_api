# Run from this repository with:
#
#   OXIDE_HOST=https://rack.example.com OXIDE_TOKEN=... \
#   OXIDE_PROJECT=demo OXIDE_VPC=app OXIDE_SUBNET=frontend \
#     mix run examples/common_workflows.exs
#
# This example creates or reuses the named project, VPC, and subnet.

project_name = System.fetch_env!("OXIDE_PROJECT")
vpc_name = System.get_env("OXIDE_VPC") || "app"
subnet_name = System.get_env("OXIDE_SUBNET") || "frontend"
ipv4_block = System.get_env("OXIDE_IPV4_BLOCK") || "10.0.0.0/24"

{:ok, oxide} = OxideApi.new()

{:ok, project} =
  OxideApi.Workflows.ensure_project(oxide,
    name: project_name,
    description: "Managed by oxide_api example"
  )

{:ok, %{vpc: vpc, subnet: subnet}} =
  OxideApi.Workflows.ensure_vpc_and_subnet(
    oxide,
    project_name,
    [name: vpc_name, description: "Example VPC"],
    name: subnet_name,
    ipv4_block: ipv4_block,
    description: "Example subnet"
  )

instances =
  oxide
  |> OxideApi.stream_instances(project: project_name, limit: 100)
  |> Enum.map(& &1["name"])

IO.puts("Project:   #{project["name"] || project_name}")
IO.puts("VPC:       #{vpc["name"] || vpc_name}")
IO.puts("Subnet:    #{subnet["name"] || subnet_name}")
IO.puts("Instances: #{Enum.join(instances, ", ")}")
