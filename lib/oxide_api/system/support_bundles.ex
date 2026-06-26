defmodule OxideApi.System.SupportBundles do
  @moduledoc """
  Experimental system support bundle endpoints.
  """

  alias OxideApi.Client

  @spec list(Client.t(), keyword()) :: Client.result()
  def list(%Client{} = client, params \\ []) do
    Client.get(client, "/experimental/v1/system/support-bundles", params: params)
  end

  @spec create(Client.t(), map()) :: Client.result()
  def create(%Client{} = client, body) when is_map(body) do
    Client.post(client, "/experimental/v1/system/support-bundles", body)
  end

  @spec get(Client.t(), String.t()) :: Client.result()
  def get(%Client{} = client, bundle_id) do
    Client.get(
      client,
      "/experimental/v1/system/support-bundles/#{Client.path_segment(bundle_id)}"
    )
  end

  @spec update(Client.t(), String.t(), map()) :: Client.result()
  def update(%Client{} = client, bundle_id, body) when is_map(body) do
    Client.put(
      client,
      "/experimental/v1/system/support-bundles/#{Client.path_segment(bundle_id)}",
      body
    )
  end

  @spec delete(Client.t(), String.t()) :: Client.result()
  def delete(%Client{} = client, bundle_id) do
    Client.delete(
      client,
      "/experimental/v1/system/support-bundles/#{Client.path_segment(bundle_id)}"
    )
  end

  @spec index(Client.t(), String.t()) :: Client.result()
  def index(%Client{} = client, bundle_id) do
    Client.get(
      client,
      "/experimental/v1/system/support-bundles/#{Client.path_segment(bundle_id)}/index"
    )
  end

  @spec download(Client.t(), String.t()) :: Client.result()
  def download(%Client{} = client, bundle_id) do
    Client.get(
      client,
      "/experimental/v1/system/support-bundles/#{Client.path_segment(bundle_id)}/download"
    )
  end

  @spec download_file(Client.t(), String.t(), String.t()) :: Client.result()
  def download_file(%Client{} = client, bundle_id, file) do
    Client.get(
      client,
      "/experimental/v1/system/support-bundles/#{Client.path_segment(bundle_id)}/download/#{Client.path_segment(file)}"
    )
  end
end
