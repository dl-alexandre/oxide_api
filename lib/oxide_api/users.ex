defmodule OxideApi.Users do
  @moduledoc """
  User endpoints.
  """

  alias OxideApi.Client

  @spec list(Client.t(), keyword()) :: Client.result()
  def list(%Client{} = client, params \\ []) do
    Client.get(client, "/v1/users", params: params)
  end

  @spec get(Client.t(), String.t()) :: Client.result()
  def get(%Client{} = client, user_id) do
    Client.get(client, "/v1/users/#{Client.path_segment(user_id)}")
  end

  @spec sessions(Client.t(), String.t(), keyword()) :: Client.result()
  def sessions(%Client{} = client, user_id, params \\ []) do
    Client.get(client, "/v1/users/#{Client.path_segment(user_id)}/sessions", params: params)
  end

  @spec access_tokens(Client.t(), String.t(), keyword()) :: Client.result()
  def access_tokens(%Client{} = client, user_id, params \\ []) do
    Client.get(client, "/v1/users/#{Client.path_segment(user_id)}/access-tokens", params: params)
  end

  @spec logout(Client.t(), String.t(), map()) :: Client.result()
  def logout(%Client{} = client, user_id, body \\ %{}) when is_map(body) do
    Client.post(client, "/v1/users/#{Client.path_segment(user_id)}/logout", body)
  end
end
