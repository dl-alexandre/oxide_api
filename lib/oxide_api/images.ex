defmodule OxideApi.Images do
  @moduledoc """
  Image endpoints.
  """

  alias OxideApi.Client

  @spec list(Client.t(), keyword()) :: Client.result()
  def list(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/images", params: params)
  end

  @spec create(Client.t(), map(), keyword()) :: Client.result()
  def create(%Client{} = client, body, params \\ []) when is_map(body) do
    Client.post(client, "/v1/images", body, params: params)
  end

  @spec get(Client.t(), String.t(), keyword()) :: Client.result()
  def get(%Client{} = client, image, params \\ []) do
    Client.get(client, "/v1/images/#{Client.path_segment(image)}", params: params)
  end

  @spec update(Client.t(), String.t(), map(), keyword()) :: Client.result()
  def update(%Client{} = client, image, body, params \\ []) when is_map(body) do
    Client.put(client, "/v1/images/#{Client.path_segment(image)}", body, params: params)
  end

  @spec delete(Client.t(), String.t(), keyword()) :: Client.result()
  def delete(%Client{} = client, image, params \\ []) do
    Client.delete(client, "/v1/images/#{Client.path_segment(image)}", params: params)
  end

  @spec promote(Client.t(), String.t(), map(), keyword()) :: Client.result()
  def promote(%Client{} = client, image, body \\ %{}, params \\ []) when is_map(body) do
    Client.post(client, "/v1/images/#{Client.path_segment(image)}/promote", body, params: params)
  end

  @spec demote(Client.t(), String.t(), map(), keyword()) :: Client.result()
  def demote(%Client{} = client, image, body \\ %{}, params \\ []) when is_map(body) do
    Client.post(client, "/v1/images/#{Client.path_segment(image)}/demote", body, params: params)
  end
end
