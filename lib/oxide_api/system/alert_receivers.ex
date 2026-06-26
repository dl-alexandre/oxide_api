defmodule OxideApi.System.AlertReceivers do
  @moduledoc """
  System alert receiver endpoints.
  """

  alias OxideApi.{AlertReceivers, Client}

  @spec list(Client.t(), keyword()) :: Client.result()
  defdelegate list(client, params \\ []), to: AlertReceivers

  @spec create(Client.t(), map()) :: Client.result()
  defdelegate create(client, body), to: AlertReceivers

  @spec get(Client.t(), String.t()) :: Client.result()
  defdelegate get(client, receiver), to: AlertReceivers

  @spec update(Client.t(), String.t(), map()) :: Client.result()
  defdelegate update(client, receiver, body), to: AlertReceivers

  @spec delete(Client.t(), String.t()) :: Client.result()
  defdelegate delete(client, receiver), to: AlertReceivers

  @spec deliveries(Client.t(), String.t(), keyword()) :: Client.result()
  defdelegate deliveries(client, receiver, params \\ []), to: AlertReceivers

  @spec probe(Client.t(), String.t(), map()) :: Client.result()
  defdelegate probe(client, receiver, body \\ %{}), to: AlertReceivers

  @spec subscriptions(Client.t(), String.t(), keyword()) :: Client.result()
  defdelegate subscriptions(client, receiver, params \\ []), to: AlertReceivers

  @spec create_subscription(Client.t(), String.t(), map()) :: Client.result()
  defdelegate create_subscription(client, receiver, body), to: AlertReceivers

  @spec delete_subscription(Client.t(), String.t(), String.t()) :: Client.result()
  defdelegate delete_subscription(client, receiver, subscription), to: AlertReceivers
end
