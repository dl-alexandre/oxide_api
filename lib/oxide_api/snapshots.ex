defmodule OxideApi.Snapshots do
  @moduledoc """
  Snapshot endpoints.
  """

  alias OxideApi.Client

  @spec list(Client.t(), keyword()) :: Client.result()
  def list(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/snapshots", params: params)
  end

  @spec create(Client.t(), map(), keyword()) :: Client.result()
  def create(%Client{} = client, body, params \\ []) when is_map(body) do
    Client.post(client, "/v1/snapshots", body, params: params)
  end

  @spec get(Client.t(), String.t(), keyword()) :: Client.result()
  def get(%Client{} = client, snapshot, params \\ []) do
    Client.get(client, "/v1/snapshots/#{Client.path_segment(snapshot)}", params: params)
  end

  @spec delete(Client.t(), String.t(), keyword()) :: Client.result()
  def delete(%Client{} = client, snapshot, params \\ []) do
    Client.delete(client, "/v1/snapshots/#{Client.path_segment(snapshot)}", params: params)
  end
end
