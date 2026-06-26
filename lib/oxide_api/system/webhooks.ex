defmodule OxideApi.System.Webhooks do
  @moduledoc """
  System webhook receiver and secret endpoints.
  """

  alias OxideApi.{Client, Webhooks}

  @spec list_receivers(Client.t(), keyword()) :: Client.result()
  defdelegate list_receivers(client, params \\ []), to: Webhooks

  @spec create_receiver(Client.t(), map()) :: Client.result()
  defdelegate create_receiver(client, body), to: Webhooks

  @spec get_receiver(Client.t(), String.t()) :: Client.result()
  defdelegate get_receiver(client, receiver), to: Webhooks

  @spec update_receiver(Client.t(), String.t(), map()) :: Client.result()
  defdelegate update_receiver(client, receiver, body), to: Webhooks

  @spec delete_receiver(Client.t(), String.t()) :: Client.result()
  defdelegate delete_receiver(client, receiver), to: Webhooks

  @spec list_secrets(Client.t(), keyword()) :: Client.result()
  defdelegate list_secrets(client, params \\ []), to: Webhooks

  @spec create_secret(Client.t(), map()) :: Client.result()
  defdelegate create_secret(client, body), to: Webhooks

  @spec delete_secret(Client.t(), String.t()) :: Client.result()
  defdelegate delete_secret(client, secret_id), to: Webhooks
end
