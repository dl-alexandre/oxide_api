defmodule OxideApi.Certificates do
  @moduledoc """
  Certificate endpoints.
  """

  alias OxideApi.Client

  @spec list(Client.t(), keyword()) :: Client.result()
  def list(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/certificates", params: params)
  end

  @spec create(Client.t(), map()) :: Client.result()
  def create(%Client{} = client, body) when is_map(body) do
    Client.post(client, "/v1/certificates", body)
  end

  @spec get(Client.t(), String.t()) :: Client.result()
  def get(%Client{} = client, certificate) do
    Client.get(client, "/v1/certificates/#{Client.path_segment(certificate)}")
  end

  @spec delete(Client.t(), String.t()) :: Client.result()
  def delete(%Client{} = client, certificate) do
    Client.delete(client, "/v1/certificates/#{Client.path_segment(certificate)}")
  end
end
