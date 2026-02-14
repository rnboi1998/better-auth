defmodule BetterAuth.Plugins.TwoFactor do
  @moduledoc """
  Plugin for Two Factor Authentication (TOTP).
  """
  alias BetterAuth.{User, TwoFactor}
  alias BetterAuth.Core.Password
  import Ecto.Query

  defp repo do
    Application.get_env(:better_auth, :repo) || raise "BetterAuth repo not configured"
  end

  def enable(user, password) do
    # Validate password first
    user = repo().preload(user, :accounts)
    account = Enum.find(user.accounts, fn a -> a.provider_id == "credential" end)

    if account && Password.verify(password, account.password) do
      # Generate Secret
      secret = Base.encode32(:crypto.strong_rand_bytes(10), padding: false)
      # Generate Backup Codes
      backup_codes = Enum.map(1..10, fn _ -> Base.encode16(:crypto.strong_rand_bytes(5)) end) |> Enum.join(",")

      # Save to DB
      attrs = %{
        user_id: user.id,
        secret: secret,
        backup_codes: backup_codes
      }

      %TwoFactor{}
      |> TwoFactor.changeset(attrs)
      |> repo().insert()

      # Update user
      user
      |> Ecto.Changeset.change(two_factor_enabled: true)
      |> repo().update()

      {:ok, %{secret: secret, backup_codes: String.split(backup_codes, ",")}}
    else
      {:error, :invalid_password}
    end
  end

  def disable(user, password) do
    user = repo().preload(user, :accounts)
    account = Enum.find(user.accounts, fn a -> a.provider_id == "credential" end)

    if account && Password.verify(password, account.password) do
      # Remove 2FA record
      from(t in TwoFactor, where: t.user_id == ^user.id) |> repo().delete_all()

      # Update user
      user
      |> Ecto.Changeset.change(two_factor_enabled: false)
      |> repo().update()

      {:ok, true}
    else
      {:error, :invalid_password}
    end
  end

  def verify_totp(user, code) do
     user = repo().preload(user, :two_factor)

     if user.two_factor do
       # NimbleTOTP requires the secret to be decoded
       case Base.decode32(user.two_factor.secret, padding: false) do
         {:ok, secret} ->
            if NimbleTOTP.valid?(secret, code) do
              {:ok, true}
            else
              {:error, :invalid_code}
            end
         _ ->
            {:error, :invalid_secret}
       end
     else
       {:error, :two_factor_not_enabled}
     end
  end
end
