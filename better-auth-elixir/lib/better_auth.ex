defmodule BetterAuth do
  @moduledoc """
  BetterAuth public API.
  """
  alias BetterAuth.Core.{User, Session, Password}

  def sign_in_email(email, password) do
    case User.authenticate(email, password) do
      {:ok, user} ->
        {:ok, session} = Session.create(user.id)
        {:ok, user, session}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def sign_up_email(email, password, name) do
    case User.create(email, password, name) do
      {:ok, user} ->
        {:ok, session} = Session.create(user.id)
        {:ok, user, session}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def sign_out(token) do
    Session.delete(token)
  end

  def get_session(token) do
    Session.get(token)
  end
end
