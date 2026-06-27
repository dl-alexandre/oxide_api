# Run from this repository with:
#
#   OXIDE_PROJECT=prod OXIDE_INSTANCE=web mix run examples/oban_jobs.exs
#
# This example builds Oban changesets. Insert them with `Oban.insert/1` or
# `Oban.insert_all/1` inside an application configured with Oban.

project = System.fetch_env!("OXIDE_PROJECT")
instance = System.fetch_env!("OXIDE_INSTANCE")

provision_job =
  OxideApi.Job.provision_instance(%{
    client_id: project,
    project: project,
    instance: %{
      name: instance,
      hostname: "#{instance}-1",
      ncpus: 2,
      memory: 4_294_967_296
    },
    disk: %{name: "boot", size: 21_474_836_480},
    wait_until: "running",
    interval: 1_000,
    timeout: 120_000
  })

wait_job =
  OxideApi.Job.wait_for_instance(%{
    client_id: project,
    project: project,
    instance: instance,
    state: "running",
    interval: 1_000,
    timeout: 120_000
  })

IO.inspect(provision_job, label: "provision instance job")
IO.inspect(wait_job, label: "wait for instance job")
