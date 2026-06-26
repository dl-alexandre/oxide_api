defmodule OxideApi.System.Alerts do
  @moduledoc """
  System alert endpoints.
  """

  alias OxideApi.{Alerts, Client}

  @spec classes(Client.t(), keyword()) :: Client.result()
  defdelegate classes(client, params \\ []), to: Alerts

  @spec resend(Client.t(), String.t(), map()) :: Client.result()
  defdelegate resend(client, alert_id, body \\ %{}), to: Alerts
end
