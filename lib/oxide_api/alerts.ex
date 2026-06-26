defmodule OxideApi.Alerts do
  @moduledoc """
  Alert endpoints.
  """

  alias OxideApi.Client

  @spec classes(Client.t(), keyword()) :: Client.result()
  def classes(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/alert-classes", params: params)
  end

  @spec resend(Client.t(), String.t(), map()) :: Client.result()
  def resend(%Client{} = client, alert_id, body \\ %{}) when is_map(body) do
    Client.post(client, "/v1/alerts/#{Client.path_segment(alert_id)}/resend", body)
  end
end
