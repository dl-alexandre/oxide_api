defmodule OxideApi.Metrics do
  @moduledoc """
  Metrics endpoints.
  """

  alias OxideApi.Client

  @spec get(Client.t(), String.t(), keyword()) :: Client.result()
  def get(%Client{} = client, metric_name, params \\ []) do
    Client.get(client, "/v1/metrics/#{Client.path_segment(metric_name)}", params: params)
  end
end
