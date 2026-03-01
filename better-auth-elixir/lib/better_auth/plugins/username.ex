defmodule BetterAuth.Plugins.Username do
  @moduledoc """
  Plugin for username based authentication.
  """
  alias BetterAuth.{User, Account, Session}
  alias BetterAuth.Core.Password
  import Ecto.Query

  @dummy_hash "$argon2id$v=19$m=65536,t=2,p=1$c29tZXNhbHQ$RdescudvJCsgt3ub+b+dWRWJTmqpvBSlBpxvF+0sbMg"

  defp repo do
    Application.get_env(:better_auth, :repo) || raise "BetterAuth repo not configured"
  end

  def sign_in_username(username, password) do
    user = repo().get_by(User, username: username) |> repo().preload(:accounts)

    case user do
      nil ->
        Password.verify("password", @dummy_hash)
        {:error, :invalid_credentials}

      user ->
        account = Enum.find(user.accounts, fn a -> a.provider_id == "credential" end)
        if account && Password.verify(password, account.password) do
          {:ok, session} = BetterAuth.Core.Session.create(user.id)
          {:ok, user, session}
        else
          {:error, :invalid_credentials}
        end
    end
  end

  def check_availability(username) do
    case repo().get_by(User, username: username) do
      nil -> {:ok, true}
      _ -> {:ok, false}
    end
  end
end
