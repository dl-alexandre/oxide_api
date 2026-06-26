defmodule OxideApi.Disks do
  @moduledoc """
  Disk endpoints.
  """

  alias OxideApi.Client

  @spec list(Client.t(), keyword()) :: Client.result()
  def list(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/disks", params: params)
  end

  @spec stream(Client.t(), keyword() | map()) :: Enumerable.t()
  def stream(%Client{} = client, params \\ []) do
    Client.stream_items(client, "/v1/disks", params)
  end

  @spec create(Client.t(), map(), keyword()) :: Client.result()
  def create(%Client{} = client, body, params \\ []) when is_map(body) do
    Client.post(client, "/v1/disks", body, params: params)
  end

  @spec get(Client.t(), String.t(), keyword()) :: Client.result()
  def get(%Client{} = client, disk, params \\ []) do
    Client.get(client, "/v1/disks/#{Client.path_segment(disk)}", params: params)
  end

  @spec delete(Client.t(), String.t(), keyword()) :: Client.result()
  def delete(%Client{} = client, disk, params \\ []) do
    Client.delete(client, "/v1/disks/#{Client.path_segment(disk)}", params: params)
  end

  @spec bulk_write_start(Client.t(), String.t(), map(), keyword()) :: Client.result()
  def bulk_write_start(%Client{} = client, disk, body, params \\ []) when is_map(body) do
    Client.post(client, "/v1/disks/#{Client.path_segment(disk)}/bulk-write-start", body,
      params: params
    )
  end

  @spec bulk_write(Client.t(), String.t(), map(), keyword()) :: Client.result()
  def bulk_write(%Client{} = client, disk, body, params \\ []) when is_map(body) do
    Client.post(client, "/v1/disks/#{Client.path_segment(disk)}/bulk-write", body, params: params)
  end

  @spec bulk_write_stop(Client.t(), String.t(), map(), keyword()) :: Client.result()
  def bulk_write_stop(%Client{} = client, disk, body, params \\ []) when is_map(body) do
    Client.post(client, "/v1/disks/#{Client.path_segment(disk)}/bulk-write-stop", body,
      params: params
    )
  end

  @spec finalize(Client.t(), String.t(), keyword()) :: Client.result()
  def finalize(%Client{} = client, disk, params \\ []) do
    Client.post(client, "/v1/disks/#{Client.path_segment(disk)}/finalize", %{}, params: params)
  end
end
