defmodule OxideApi.Projects do
  @moduledoc """
  Project endpoints.
  """

  alias OxideApi.Client

  @spec list(Client.t(), keyword()) :: Client.result()
  def list(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/projects", params: params)
  end

  @spec stream(Client.t(), keyword() | map()) :: Enumerable.t()
  def stream(%Client{} = client, params \\ []) do
    Client.stream_items(client, "/v1/projects", params)
  end

  @spec create(Client.t(), map()) :: Client.result()
  def create(%Client{} = client, body) when is_map(body) do
    Client.post(client, "/v1/projects", body)
  end

  @spec get(Client.t(), String.t()) :: Client.result()
  def get(%Client{} = client, project) do
    Client.get(client, "/v1/projects/#{Client.path_segment(project)}")
  end

  @spec update(Client.t(), String.t(), map()) :: Client.result()
  def update(%Client{} = client, project, body) when is_map(body) do
    Client.put(client, "/v1/projects/#{Client.path_segment(project)}", body)
  end

  @spec delete(Client.t(), String.t()) :: Client.result()
  def delete(%Client{} = client, project) do
    Client.delete(client, "/v1/projects/#{Client.path_segment(project)}")
  end

  @spec get_policy(Client.t(), String.t()) :: Client.result()
  def get_policy(%Client{} = client, project) do
    Client.get(client, "/v1/projects/#{Client.path_segment(project)}/policy")
  end

  @spec update_policy(Client.t(), String.t(), map()) :: Client.result()
  def update_policy(%Client{} = client, project, body) when is_map(body) do
    Client.put(client, "/v1/projects/#{Client.path_segment(project)}/policy", body)
  end
end
