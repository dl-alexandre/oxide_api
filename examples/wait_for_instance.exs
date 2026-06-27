# Run from this repository with:
#
#   OXIDE_HOST=https://rack.example.com OXIDE_TOKEN=... \
#   OXIDE_PROJECT=prod OXIDE_INSTANCE=web \
#     mix run examples/wait_for_instance.exs

project = System.fetch_env!("OXIDE_PROJECT")
instance = System.fetch_env!("OXIDE_INSTANCE")
timeout = System.get_env("OXIDE_WAIT_TIMEOUT", "120000") |> String.to_integer()

{:ok, oxide} = OxideApi.new()

case OxideApi.wait_instance_running(oxide, instance,
       project: project,
       interval: 1_000,
       timeout: timeout,
       on_change: fn previous, current, resource ->
         IO.puts("#{resource["name"] || instance}: #{previous} -> #{current}")
         :ok
       end
     ) do
  {:ok, resource} ->
    IO.puts("Instance #{resource["name"] || instance} is running")

  {:error, :timeout} ->
    IO.puts("Timed out waiting for #{instance} to run")
    System.halt(75)

  {:error, reason} ->
    IO.puts("Failed while waiting for #{instance}: #{inspect(reason)}")
    System.halt(1)
end
