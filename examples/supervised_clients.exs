# Run from this repository with:
#
#   OXIDE_HOST=https://rack.example.com OXIDE_TOKEN=... OXIDE_PROJECT=prod \
#     mix run examples/supervised_clients.exs

project = System.fetch_env!("OXIDE_PROJECT")

{:ok, _supervisor} = OxideApi.Supervisor.start_link(cache: true)

{:ok, _pid} =
  OxideApi.start_project_client(project,
    host: System.fetch_env!("OXIDE_HOST"),
    token: System.fetch_env!("OXIDE_TOKEN")
  )

{:ok, oxide} = OxideApi.fetch_client({:project, project})

{:ok, projects} =
  OxideApi.Cache.fetch(OxideApi.Cache, {:projects, project}, 30_000, fn ->
    OxideApi.fetch_all(oxide, :project_list)
  end)

IO.puts("Supervised client for project #{project}")
IO.puts("Visible projects: #{Enum.map_join(projects, ", ", & &1["name"])}")
