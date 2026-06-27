# Run from this repository with:
#
#   OXIDE_HOST=https://rack.example.com OXIDE_TOKEN=... OXIDE_PROJECT=prod \
#     mix run examples/ash_resources.exs

project = System.fetch_env!("OXIDE_PROJECT")

{:ok, oxide} = OxideApi.new()

{:ok, projects} = OxideApi.Ash.Domain.list_projects(oxide)
{:ok, instances} = OxideApi.Ash.Domain.list_instances(oxide, project)
{:ok, disks} = OxideApi.Ash.Domain.list_disks(oxide, project)

IO.puts("Projects")
Enum.each(projects, &IO.puts("  #{&1.name}"))

IO.puts("Instances in #{project}")
Enum.each(instances, &IO.puts("  #{&1.name} #{&1.run_state}"))

IO.puts("Disks in #{project}")
Enum.each(disks, &IO.puts("  #{&1.name} #{&1.state || "unknown"}"))
