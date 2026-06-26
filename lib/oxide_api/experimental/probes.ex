defmodule OxideApi.Experimental.Probes do
  @moduledoc """
  Experimental probe endpoints.
  """

  alias OxideApi.Client

  @spec list(Client.t(), keyword()) :: Client.result()
  def list(%Client{} = client, params \\ []) do
    Client.get(client, "/experimental/v1/probes", params: params)
  end

  @spec create(Client.t(), map()) :: Client.result()
  def create(%Client{} = client, body) when is_map(body) do
    Client.post(client, "/experimental/v1/probes", body)
  end

  @spec get(Client.t(), String.t()) :: Client.result()
  def get(%Client{} = client, probe) do
    Client.get(client, "/experimental/v1/probes/#{Client.path_segment(probe)}")
  end

  @spec delete(Client.t(), String.t()) :: Client.result()
  def delete(%Client{} = client, probe) do
    Client.delete(client, "/experimental/v1/probes/#{Client.path_segment(probe)}")
  end
end
