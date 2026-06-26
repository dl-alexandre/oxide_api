defmodule OxideApi.System.AuditLog do
  @moduledoc """
  System audit log endpoints.
  """

  alias OxideApi.Client

  @spec list(Client.t(), keyword()) :: Client.result()
  def list(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/system/audit-log", params: params)
  end
end
