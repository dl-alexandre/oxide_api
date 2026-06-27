if Code.ensure_loaded?(Oban.Worker) do
  defmodule OxideApi.Oban.ProvisionInstanceWorker do
    @moduledoc """
    Oban worker that creates an instance with a boot disk and optionally waits
    for it to reach a desired state.
    """

    use Oban.Worker,
      queue: :oxide_api,
      max_attempts: 5,
      unique: [period: 300, keys: [:client_id, :project, :name]]

    @impl Oban.Worker
    def perform(%Oban.Job{args: args}) do
      OxideApi.Job.perform_provision_instance(args)
    end
  end
else
  defmodule OxideApi.Oban.ProvisionInstanceWorker do
    @moduledoc """
    Stub module used when Oban is not available.
    """

    def new(_args, _opts \\ []), do: {:error, :oban_not_loaded}
    def perform(_job), do: {:error, :oban_not_loaded}
  end
end
