if Code.ensure_loaded?(Oban.Worker) do
  defmodule OxideApi.Oban.RequestOperationWorker do
    @moduledoc """
    Oban worker for executing a generated Oxide operation ID.
    """

    use Oban.Worker,
      queue: :oxide_api,
      max_attempts: 5

    @impl Oban.Worker
    def perform(%Oban.Job{args: args}) do
      OxideApi.Job.perform_request_operation(args)
    end
  end
else
  defmodule OxideApi.Oban.RequestOperationWorker do
    @moduledoc """
    Stub module used when Oban is not available.
    """

    def new(_args, _opts \\ []), do: {:error, :oban_not_loaded}
    def perform(_job), do: {:error, :oban_not_loaded}
  end
end
