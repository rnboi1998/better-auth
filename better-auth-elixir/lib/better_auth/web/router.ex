defmodule BetterAuth.Web.Router do
  @moduledoc """
  Provides routes for BetterAuth and its plugins.
  """

  defmacro better_auth_routes(opts \\ []) do
    quote do
      scope alias: false do
        # Core
        post "/sign-in/email", BetterAuth.Web.Controller, :sign_in_email
        post "/sign-up/email", BetterAuth.Web.Controller, :sign_up_email
        post "/sign-out", BetterAuth.Web.Controller, :sign_out
        get "/session", BetterAuth.Web.Controller, :get_session

        # Plugin: Username
        post "/sign-in/username", BetterAuth.Web.Controller, :sign_in_username
        post "/is-username-available", BetterAuth.Web.Controller, :check_username_availability

        # Plugin: Two Factor
        post "/two-factor/enable", BetterAuth.Web.Controller, :enable_two_factor
        post "/two-factor/disable", BetterAuth.Web.Controller, :disable_two_factor
        post "/two-factor/verify", BetterAuth.Web.Controller, :verify_two_factor

        # Plugin: Organization
        post "/organization/create", BetterAuth.Web.Controller, :create_organization
        get "/organization/list", BetterAuth.Web.Controller, :list_organizations
        post "/organization/invite", BetterAuth.Web.Controller, :invite_member

        # Plugin: SSO (Enterprise OIDC)
        post "/sso/register", BetterAuth.Web.Controller, :register_sso_provider
        post "/sign-in/sso", BetterAuth.Web.Controller, :sign_in_sso
        get "/sso/callback/:provider_id", BetterAuth.Web.Controller, :callback_sso

        # Plugin: OIDC Provider (IdP)
        get "/.well-known/openid-configuration", BetterAuth.Web.Controller, :oidc_discovery
        get "/jwks.json", BetterAuth.Web.Controller, :oidc_jwks
        get "/oauth2/authorize", BetterAuth.Web.Controller, :oidc_authorize
        post "/oauth2/token", BetterAuth.Web.Controller, :oidc_token
        get "/oauth2/userinfo", BetterAuth.Web.Controller, :oidc_userinfo
      end
    end
  end
end
