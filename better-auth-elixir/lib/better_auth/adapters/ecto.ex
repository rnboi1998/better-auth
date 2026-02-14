defmodule BetterAuth.Adapters.Ecto do
  @behaviour BetterAuth.Adapter

  alias BetterAuth.{User, Session, Account}
  import Ecto.Query

  defp repo do
    Application.get_env(:better_auth, :repo) || raise "BetterAuth repo not configured"
  end

  @impl true
  def create_user(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> repo().insert()
  end

  @impl true
  def get_user_by_email(email) do
    user = repo().get_by(User, email: email) |> repo().preload(:accounts)
    {:ok, user}
  end

  @impl true
  def create_session(attrs) do
    %Session{}
    |> Session.changeset(attrs)
    |> repo().insert()
  end

  @impl true
  def get_session_by_token(token) do
    session = repo().get_by(Session, token: token) |> repo().preload(:user)
    {:ok, session}
  end

  @impl true
  def delete_session(token) do
    case repo().get_by(Session, token: token) do
      nil -> {:error, :not_found}
      session -> repo().delete(session)
    end
  end

  @impl true
  def create_account(attrs) do
    %Account{}
    |> Account.changeset(attrs)
    |> repo().insert()
  end

  @impl true
  def create_user_with_account(user_attrs, account_attrs) do
    multi =
      Ecto.Multi.new()
      |> Ecto.Multi.insert(:user, User.changeset(%User{}, user_attrs))
      |> Ecto.Multi.run(:account, fn repo, %{user: user} ->
        account_attrs = Map.put(account_attrs, :user_id, user.id)
        Account.changeset(%Account{}, account_attrs)
        |> repo.insert()
      end)

    case repo().transaction(multi) do
      {:ok, %{user: user, account: _account}} ->
        # Preload accounts if needed, but here we return user
        # We might want to return user with accounts preloaded
        {:ok, %{user | accounts: []}} # Empty accounts initially or fetch if needed
      {:error, :user, changeset, _changes} ->
        {:error, changeset}
      {:error, :account, changeset, _changes} ->
        {:error, changeset}
    end
  end
end
