defmodule OxideApi.Result do
  @moduledoc """
  Helpers for working with `{:ok, value}` / `{:error, reason}` API results.

  The endpoint wrappers intentionally return plain result tuples. This module
  keeps common agent-loop decisions explicit: successful value, not found,
  retryable API failure, transport failure, or permanent API failure.
  """

  alias OxideApi.Error

  @type result :: {:ok, term()} | {:error, Error.t() | {:transport_error, term()} | term()}

  @type category ::
          :ok
          | :not_found
          | :rate_limited
          | :retryable
          | :transport_error
          | :configuration_error
          | :permanent_error
          | :unknown_error

  @doc """
  Returns true for successful result tuples.
  """
  @spec ok?(result()) :: boolean()
  def ok?({:ok, _value}), do: true
  def ok?(_result), do: false

  @doc """
  Returns true for error result tuples.
  """
  @spec error?(result()) :: boolean()
  def error?({:error, _reason}), do: true
  def error?(_result), do: false

  @doc """
  Classifies a result for agent loops and retry policies.
  """
  @spec category(result()) :: category()
  def category({:ok, _value}), do: :ok

  def category({:error, %Error{error_code: "configuration_error"}}), do: :configuration_error

  def category({:error, %Error{} = error}) do
    cond do
      Error.not_found?(error) -> :not_found
      Error.rate_limited?(error) -> :rate_limited
      Error.retryable?(error) -> :retryable
      true -> :permanent_error
    end
  end

  def category({:error, {:transport_error, _reason}}), do: :transport_error
  def category({:error, _reason}), do: :unknown_error
  def category(_result), do: :unknown_error

  @doc """
  Returns true for 404/not-found API errors.
  """
  @spec not_found?(result()) :: boolean()
  def not_found?(result), do: category(result) == :not_found

  @doc """
  Returns true for API errors that can reasonably be retried.

  Transport errors are intentionally classified separately by
  `transport_error?/1`.
  """
  @spec retryable?(result()) :: boolean()
  def retryable?(result), do: category(result) in [:rate_limited, :retryable]

  @doc """
  Returns true for transport failures returned by `Req`.
  """
  @spec transport_error?(result()) :: boolean()
  def transport_error?(result), do: category(result) == :transport_error

  @doc """
  Returns true for errors that should not be retried automatically.
  """
  @spec permanent_error?(result()) :: boolean()
  def permanent_error?(result), do: category(result) in [:configuration_error, :permanent_error]

  @doc """
  Returns the success value or `default` for errors.
  """
  @spec value(result(), term()) :: term()
  def value(result, default \\ nil)
  def value({:ok, value}, _default), do: value
  def value({:error, _reason}, default), do: default
  def value(_result, default), do: default

  @doc """
  Returns a result tagged with its error category.

  Successful results are returned unchanged. Error results become
  `{:error, category, reason}`.
  """
  @spec tagged(result()) :: {:ok, term()} | {:error, category(), term()}
  def tagged({:ok, value}), do: {:ok, value}
  def tagged({:error, reason} = result), do: {:error, category(result), reason}

  @doc """
  Returns the success value or raises the underlying error.
  """
  @spec unwrap!(result()) :: term()
  def unwrap!({:ok, value}), do: value
  def unwrap!({:error, %Error{} = error}), do: raise(error)

  def unwrap!({:error, {:transport_error, reason}}) do
    raise RuntimeError, "Oxide API transport error: #{inspect(reason)}"
  end

  def unwrap!({:error, reason}) do
    raise RuntimeError, "Oxide API error: #{inspect(reason)}"
  end
end
