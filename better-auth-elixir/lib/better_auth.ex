defmodule BetterAuth do
  @moduledoc """
  BetterAuth public API.
  """
  alias BetterAuth.Core.{User, Session}

  # Delegate to Core
  defdelegate sign_in_email(email, password), to: BetterAuth.Core.User, as: :authenticate
  defdelegate sign_up_email(email, password, name), to: BetterAuth.Core.User, as: :create

  def sign_out(token) do
    Session.delete(token)
  end

  def get_session(token) do
    Session.get(token)
  end

  # Plugin delegations (optional, or accessed directly via Plugins modules)
  # But good practice to expose them here if we want a unified API surface

  defdelegate sign_in_username(username, password), to: BetterAuth.Plugins.Username
end
