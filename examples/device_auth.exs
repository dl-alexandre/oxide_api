# Run from this repository with:
#
#   OXIDE_HOST=https://rack.example.com mix run examples/device_auth.exs
#
# Set OXIDE_TOKEN_PATH to store the token somewhere other than
# ~/.config/oxide_api/token.

host = System.fetch_env!("OXIDE_HOST")
client_id = System.get_env("OXIDE_CLIENT_ID") || "oxide-cli"
token_path = System.get_env("OXIDE_TOKEN_PATH") || Path.expand("~/.config/oxide_api/token")

{:ok, auth_client} = OxideApi.new_unauthenticated(host: host)
{:ok, auth} = OxideApi.Login.device_auth(auth_client, client_id: client_id)

IO.puts("Device code: #{auth["device_code"]}")
IO.puts("User code:   #{auth["user_code"]}")
IO.puts("Open:        #{auth["verification_uri"] || auth["verification_uri_complete"]}")

interval_seconds = Map.get(auth, "interval", 5)
expires_in_seconds = Map.get(auth, "expires_in", 600)
deadline = System.monotonic_time(:second) + expires_in_seconds

token =
  Stream.repeatedly(fn ->
    Process.sleep(interval_seconds * 1000)

    OxideApi.Login.device_token(
      auth_client,
      client_id: client_id,
      device_code: auth["device_code"],
      grant_type: "urn:ietf:params:oauth:grant-type:device_code"
    )
  end)
  |> Enum.reduce_while(nil, fn
    {:ok, token}, _acc ->
      {:halt, token}

    {:error, %OxideApi.Error{details: %{"error" => "authorization_pending"}}}, _acc ->
      if System.monotonic_time(:second) < deadline do
        {:cont, nil}
      else
        raise "device authorization expired"
      end

    {:error, reason}, _acc ->
      raise "device token request failed: #{inspect(reason)}"
  end)

File.mkdir_p!(Path.dirname(token_path))
File.write!(token_path, token["access_token"])

{:ok, oxide} = OxideApi.new(host: host, token: token["access_token"])
{:ok, me} = OxideApi.Me.get(oxide)

IO.puts("Stored token at #{token_path}")
IO.puts("Authenticated as #{me["display_name"] || me["id"] || "current user"}")
