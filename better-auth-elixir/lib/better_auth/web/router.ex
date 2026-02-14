defmodule BetterAuth.Web.Router do
  @moduledoc """
  Provides routes for BetterAuth.
  """

  defmacro better_auth_routes(opts \\ []) do
    quote do
      scope alias: false do
        post "/sign-in/email", BetterAuth.Web.Controller, :sign_in_email
        post "/sign-up/email", BetterAuth.Web.Controller, :sign_up_email
        post "/sign-out", BetterAuth.Web.Controller, :sign_out
        get "/session", BetterAuth.Web.Controller, :get_session
      end
    end
  end
end
