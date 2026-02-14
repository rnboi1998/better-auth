defmodule BetterAuth.Core.User do
  alias BetterAuth.{User, Account}
  alias BetterAuth.Core.Password

  @dummy_hash "$argon2id$v=19$m=65536,t=2,p=1$c29tZXNhbHQ$RdescudvJCsgt3ub+b+dWRWJTmqpvBSlBpxvF+0sbMg"

  defp adapter do
    Application.get_env(:better_auth, :adapter, BetterAuth.Adapters.Ecto)
  end

  def create(email, password, name) do
    case adapter().get_user_by_email(email) do
      {:ok, nil} ->
        hashed_password = Password.hash(password)

        user_attrs = %{email: email, name: name}
        account_attrs = %{
          provider_id: "credential",
          account_id: email,
          password: hashed_password
        }

        adapter().create_user_with_account(user_attrs, account_attrs)

      {:ok, _user} ->
        {:error, :email_already_exists}

      error ->
        error
    end
  end

  def authenticate(email, password) do
    case adapter().get_user_by_email(email) do
      {:ok, nil} ->
        # To prevent timing attacks, simulate verification
        Password.verify("password", @dummy_hash)
        {:error, :invalid_credentials}

      {:ok, user} ->
        # Find credential account
        account = Enum.find(user.accounts, fn a -> a.provider_id == "credential" end)
        if account && Password.verify(password, account.password) do
          {:ok, user}
        else
          {:error, :invalid_credentials}
        end

      error ->
        error
    end
  end
end
