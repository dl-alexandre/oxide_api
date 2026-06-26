defmodule OxideApi.FloatingIps do
  @moduledoc """
  Floating IP endpoints.
  """

  alias OxideApi.Client

  @spec list(Client.t(), keyword()) :: Client.result()
  def list(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/floating-ips", params: params)
  end

  @spec create(Client.t(), map(), keyword()) :: Client.result()
  def create(%Client{} = client, body, params \\ []) when is_map(body) do
    Client.post(client, "/v1/floating-ips", body, params: params)
  end

  @spec get(Client.t(), String.t(), keyword()) :: Client.result()
  def get(%Client{} = client, floating_ip, params \\ []) do
    Client.get(client, "/v1/floating-ips/#{Client.path_segment(floating_ip)}", params: params)
  end

  @spec update(Client.t(), String.t(), map(), keyword()) :: Client.result()
  def update(%Client{} = client, floating_ip, body, params \\ []) when is_map(body) do
    Client.put(client, "/v1/floating-ips/#{Client.path_segment(floating_ip)}", body,
      params: params
    )
  end

  @spec delete(Client.t(), String.t(), keyword()) :: Client.result()
  def delete(%Client{} = client, floating_ip, params \\ []) do
    Client.delete(client, "/v1/floating-ips/#{Client.path_segment(floating_ip)}", params: params)
  end

  @spec attach(Client.t(), String.t(), map(), keyword()) :: Client.result()
  def attach(%Client{} = client, floating_ip, body, params \\ []) when is_map(body) do
    Client.post(client, "/v1/floating-ips/#{Client.path_segment(floating_ip)}/attach", body,
      params: params
    )
  end

  @spec detach(Client.t(), String.t(), map(), keyword()) :: Client.result()
  def detach(%Client{} = client, floating_ip, body \\ %{}, params \\ []) when is_map(body) do
    Client.post(client, "/v1/floating-ips/#{Client.path_segment(floating_ip)}/detach", body,
      params: params
    )
  end
end
