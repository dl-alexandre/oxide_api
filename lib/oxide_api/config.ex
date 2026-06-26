defmodule OxideApi.Config do
  @moduledoc false

  alias OxideApi.Credentials

  @default_api_version "2026060800.0.0"
  @default_user_agent "oxide_api/0.0.1"

  @request_option_keys [
    :connect_options,
    :max_retries,
    :pool_timeout,
    :receive_timeout,
    :retry,
    :retry_delay,
    :retry_log_level
  ]

  defstruct [
    :host,
    :token,
    :api_version,
    :user_agent,
    :req_options
  ]

  @type t :: %__MODULE__{
          host: String.t() | nil,
          token: String.t() | nil,
          api_version: String.t(),
          user_agent: String.t(),
          req_options: keyword()
        }

  @doc """
  Builds client configuration from options, application env, and Oxide env vars.

  Precedence is:

  1. per-call options
  2. `Application` environment for `:oxide_api`
  3. `OXIDE_HOST` / `OXIDE_TOKEN`
  4. Oxide CLI files in `$HOME/.config/oxide`
  5. library defaults
  """
  @spec load(keyword()) :: t()
  def load(opts \\ []) do
    app_env = Application.get_all_env(:oxide_api)
    config_dir = first_present([opts[:config_dir], app_env[:config_dir]])

    file_credentials =
      Credentials.load(config_dir: config_dir || Credentials.default_config_dir())

    %__MODULE__{
      host:
        first_present([
          opts[:host],
          app_env[:host],
          System.get_env("OXIDE_HOST"),
          file_credentials[:host]
        ]),
      token:
        first_present([
          opts[:token],
          app_env[:token],
          System.get_env("OXIDE_TOKEN"),
          file_credentials[:token]
        ]),
      api_version:
        first_present([opts[:api_version], app_env[:api_version], @default_api_version]),
      user_agent: first_present([opts[:user_agent], app_env[:user_agent], @default_user_agent]),
      req_options: req_options(app_env, opts)
    }
  end

  defp req_options(app_env, opts) do
    app_env
    |> configured_req_options()
    |> Keyword.merge(configured_req_options(opts))
  end

  defp configured_req_options(opts) do
    opts
    |> Keyword.get(:req_options, [])
    |> Keyword.merge(named_req_options(opts))
  end

  defp named_req_options(opts) do
    Enum.reduce(@request_option_keys, [], fn key, acc ->
      if Keyword.has_key?(opts, key) do
        Keyword.put(acc, key, Keyword.fetch!(opts, key))
      else
        acc
      end
    end)
  end

  defp first_present(values) do
    Enum.find(values, fn
      value when is_binary(value) -> String.trim(value) != ""
      nil -> false
      _value -> true
    end)
  end
end
