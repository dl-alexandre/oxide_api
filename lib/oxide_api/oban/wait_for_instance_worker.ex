if Code.ensure_loaded?(Oban.Worker) do
  defmodule OxideApi.Oban.WaitForInstanceWorker do
    @moduledoc """
    Oban worker that waits until an instance reaches a desired state.
    """

    use Oban.Worker,
      queue: :oxide_api,
      max_attempts: 5,
      unique: [period: 300, keys: [:client_id, :project, :instance, :state]]

    @impl Oban.Worker
    def perform(%Oban.Job{args: args}) do
      OxideApi.Job.perform_wait_for_instance(args)
    end
  end
else
  defmodule OxideApi.Oban.WaitForInstanceWorker do
    @moduledoc """
    Stub module used when Oban is not available.
    """

    def new(_args, _opts \\ []), do: {:error, :oban_not_loaded}
    def perform(_job), do: {:error, :oban_not_loaded}
  end
end
