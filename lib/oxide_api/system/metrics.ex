defmodule OxideApi.System.Metrics do
  @moduledoc """
  System metrics and utilization endpoints.
  """

  alias OxideApi.Client

  @spec get(Client.t(), String.t(), keyword()) :: Client.result()
  def get(%Client{} = client, metric_name, params \\ []) do
    Client.get(client, "/v1/system/metrics/#{Client.path_segment(metric_name)}", params: params)
  end

  @spec utilization_silos(Client.t(), keyword()) :: Client.result()
  def utilization_silos(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/system/utilization/silos", params: params)
  end

  @spec utilization_silo(Client.t(), String.t(), keyword()) :: Client.result()
  def utilization_silo(%Client{} = client, silo, params \\ []) do
    Client.get(client, "/v1/system/utilization/silos/#{Client.path_segment(silo)}",
      params: params
    )
  end
end
