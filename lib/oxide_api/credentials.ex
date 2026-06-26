defmodule OxideApi.Credentials do
  @moduledoc false

  @config_file "config.toml"
  @credentials_file "credentials.toml"

  @type loaded :: %{optional(:host) => String.t(), optional(:token) => String.t()}

  @spec load(keyword()) :: loaded()
  def load(opts \\ []) do
    config_dir = Keyword.get(opts, :config_dir, default_config_dir())

    config_dir
    |> read_files()
    |> Enum.reduce(%{}, &Map.merge(&2, &1))
  end

  @spec default_config_dir() :: String.t()
  def default_config_dir do
    home = System.user_home() || "."
    Path.join([home, ".config", "oxide"])
  end

  defp read_files(config_dir) do
    [
      read_toml(Path.join(config_dir, @config_file)),
      read_toml(Path.join(config_dir, @credentials_file))
    ]
  end

  defp read_toml(path) do
    with true <- File.regular?(path),
         {:ok, contents} <- File.read(path) do
      parse_toml(contents)
    else
      _ -> %{}
    end
  end

  defp parse_toml(contents) do
    contents
    |> String.split("\n")
    |> Enum.reduce(%{}, fn line, acc ->
      line = normalize_line(line)

      case Regex.run(~r/^([A-Za-z0-9_.-]+)\s*=\s*(.+)$/, line) do
        [_, key, value] when key in ["host", "token"] ->
          Map.put_new(acc, String.to_existing_atom(key), parse_value(value))

        _ ->
          acc
      end
    end)
  end

  defp normalize_line(line) do
    line
    |> String.trim()
    |> strip_comment()
  end

  defp strip_comment(""), do: ""
  defp strip_comment("#" <> _rest), do: ""

  defp strip_comment(line) do
    case String.split(line, "#", parts: 2) do
      [value, _comment] -> String.trim(value)
      [value] -> value
    end
  end

  defp parse_value(value) do
    value = String.trim(value)

    cond do
      quoted?(value, "\"") ->
        value
        |> String.trim("\"")
        |> String.replace(~s(\\"), ~s("))
        |> String.replace(~s(\\\\), ~s(\\))

      quoted?(value, "'") ->
        String.trim(value, "'")

      true ->
        value
    end
  end

  defp quoted?(value, quote) do
    String.starts_with?(value, quote) and String.ends_with?(value, quote)
  end
end
