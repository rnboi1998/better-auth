defmodule BetterAuth.Adapter do
  @callback create_user(map()) :: {:ok, BetterAuth.User.t()} | {:error, any()}
  @callback get_user_by_email(String.t()) :: {:ok, BetterAuth.User.t() | nil} | {:error, any()}
  @callback create_session(map()) :: {:ok, BetterAuth.Session.t()} | {:error, any()}
  @callback get_session_by_token(String.t()) :: {:ok, BetterAuth.Session.t() | nil} | {:error, any()}
  @callback delete_session(String.t()) :: {:ok, BetterAuth.Session.t()} | {:error, any()}
  @callback create_account(map()) :: {:ok, BetterAuth.Account.t()} | {:error, any()}
  @callback create_user_with_account(map(), map()) :: {:ok, BetterAuth.User.t()} | {:error, any()}
  # Add more as needed
end
