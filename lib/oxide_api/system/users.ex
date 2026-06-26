defmodule OxideApi.System.Users do
  @moduledoc """
  System user endpoints.
  """

  alias OxideApi.Client

  @spec list(Client.t(), keyword()) :: Client.result()
  def list(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/system/users", params: params)
  end

  @spec get(Client.t(), String.t()) :: Client.result()
  def get(%Client{} = client, user_id) do
    Client.get(client, "/v1/system/users/#{Client.path_segment(user_id)}")
  end

  @spec delete(Client.t(), String.t()) :: Client.result()
  def delete(%Client{} = client, user_id) do
    Client.delete(client, "/v1/system/users/#{Client.path_segment(user_id)}")
  end

  @spec built_in(Client.t(), keyword()) :: Client.result()
  def built_in(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/system/users-builtin", params: params)
  end

  @spec get_built_in(Client.t(), String.t()) :: Client.result()
  def get_built_in(%Client{} = client, user) do
    Client.get(client, "/v1/system/users-builtin/#{Client.path_segment(user)}")
  end
end
