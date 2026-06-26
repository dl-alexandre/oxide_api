defmodule OxideApi.System.Update do
  @moduledoc """
  System update endpoints.
  """

  alias OxideApi.Client

  @spec status(Client.t()) :: Client.result()
  def status(%Client{} = client), do: Client.get(client, "/v1/system/update/status")

  @spec target_release(Client.t()) :: Client.result()
  def target_release(%Client{} = client),
    do: Client.get(client, "/v1/system/update/target-release")

  @spec update_target_release(Client.t(), map()) :: Client.result()
  def update_target_release(%Client{} = client, body) when is_map(body) do
    Client.put(client, "/v1/system/update/target-release", body)
  end

  @spec recovery_finish(Client.t(), map()) :: Client.result()
  def recovery_finish(%Client{} = client, body \\ %{}) when is_map(body) do
    Client.put(client, "/v1/system/update/recovery-finish", body)
  end

  @spec repositories(Client.t(), keyword()) :: Client.result()
  def repositories(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/system/update/repositories", params: params)
  end

  @spec upload_repository(Client.t(), binary(), keyword()) :: Client.result()
  def upload_repository(%Client{} = client, body, opts \\ []) when is_binary(body) do
    params = Keyword.get(opts, :params, [])
    headers = Keyword.get(opts, :headers, [])

    Client.request(client, :put, "/v1/system/update/repositories",
      body: body,
      params: params,
      headers: [{"content-type", "application/octet-stream"} | headers]
    )
  end

  @spec repository(Client.t(), String.t()) :: Client.result()
  def repository(%Client{} = client, system_version) do
    Client.get(client, "/v1/system/update/repositories/#{Client.path_segment(system_version)}")
  end

  @spec trust_roots(Client.t(), keyword()) :: Client.result()
  def trust_roots(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/system/update/trust-roots", params: params)
  end

  @spec create_trust_root(Client.t(), map()) :: Client.result()
  def create_trust_root(%Client{} = client, body) when is_map(body) do
    Client.post(client, "/v1/system/update/trust-roots", body)
  end

  @spec trust_root(Client.t(), String.t()) :: Client.result()
  def trust_root(%Client{} = client, trust_root_id) do
    Client.get(client, "/v1/system/update/trust-roots/#{Client.path_segment(trust_root_id)}")
  end

  @spec delete_trust_root(Client.t(), String.t()) :: Client.result()
  def delete_trust_root(%Client{} = client, trust_root_id) do
    Client.delete(client, "/v1/system/update/trust-roots/#{Client.path_segment(trust_root_id)}")
  end
end
