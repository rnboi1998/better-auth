defmodule BetterAuth.Web.Controller do
  use Phoenix.Controller, namespace: BetterAuth.Web
  import Plug.Conn

  alias BetterAuth
  alias BetterAuth.Plugins.{Username, TwoFactor, Organization, SSO, OIDCProvider}

  defp base_url do
    Application.get_env(:better_auth, :base_url) || "http://localhost:4000/api/auth"
  end

  # --- Core ---

  def sign_in_email(conn, %{"email" => email, "password" => password}) do
    case BetterAuth.sign_in_email(email, password) do
      {:ok, user, session} ->
        conn
        |> put_session_cookie(session.token)
        |> json(%{user: user, token: session.token})

      {:error, reason} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: format_error(reason)})
    end
  end

  def sign_up_email(conn, %{"email" => email, "password" => password, "name" => name}) do
    case BetterAuth.sign_up_email(email, password, name) do
      {:ok, user, session} ->
        conn
        |> put_session_cookie(session.token)
        |> put_status(:created)
        |> json(%{user: user, token: session.token})

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: format_error(reason)})
    end
  end

  def sign_out(conn, _params) do
    token = get_session_token(conn)
    if token do
      BetterAuth.sign_out(token)
    end

    conn
    |> delete_resp_cookie("better_auth_session_token")
    |> json(%{message: "Signed out"})
  end

  def get_session(conn, _params) do
    token = get_session_token(conn)
    case token && BetterAuth.get_session(token) do
      {:ok, session} ->
        json(conn, %{user: session.user, token: session.token})

      _ ->
        json(conn, nil)
    end
  end

  # --- Plugin: Username ---

  def sign_in_username(conn, %{"username" => username, "password" => password}) do
    case Username.sign_in_username(username, password) do
      {:ok, user, session} ->
        conn
        |> put_session_cookie(session.token)
        |> json(%{user: user, token: session.token})

      {:error, reason} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: format_error(reason)})
    end
  end

  def check_username_availability(conn, %{"username" => username}) do
    case Username.check_availability(username) do
      {:ok, available} -> json(conn, %{available: available})
      {:error, reason} ->
        conn |> put_status(:bad_request) |> json(%{error: format_error(reason)})
    end
  end

  # --- Plugin: Two Factor ---

  def enable_two_factor(conn, %{"password" => password}) do
    user = conn.assigns[:current_user]
    if user do
      case TwoFactor.enable(user, password) do
        {:ok, data} -> json(conn, data)
        {:error, reason} ->
           conn |> put_status(:bad_request) |> json(%{error: format_error(reason)})
      end
    else
      conn |> put_status(:unauthorized) |> json(%{error: "Unauthorized"})
    end
  end

  def disable_two_factor(conn, %{"password" => password}) do
    user = conn.assigns[:current_user]
    if user do
       case TwoFactor.disable(user, password) do
         {:ok, _} -> json(conn, %{status: true})
         {:error, reason} ->
            conn |> put_status(:bad_request) |> json(%{error: format_error(reason)})
       end
    else
       conn |> put_status(:unauthorized) |> json(%{error: "Unauthorized"})
    end
  end

  def verify_two_factor(conn, %{"code" => code}) do
     # This assumes user is partially authenticated or we pass a temp token
     # For now, simplistic implementation assuming logged in user verifying 2FA
     user = conn.assigns[:current_user]
     if user do
       case TwoFactor.verify_totp(user, code) do
         {:ok, true} -> json(conn, %{status: true})
         _ -> conn |> put_status(:unauthorized) |> json(%{error: "Invalid code"})
       end
     else
       conn |> put_status(:unauthorized) |> json(%{error: "Unauthorized"})
     end
  end

  # --- Plugin: Organization ---

  def create_organization(conn, %{"name" => name, "slug" => slug}) do
    user = conn.assigns[:current_user]
    if user do
      case Organization.create(user.id, name, slug) do
        {:ok, org} -> json(conn, org)
        {:error, reason} ->
           conn |> put_status(:bad_request) |> json(%{error: format_error(reason)})
      end
    else
      conn |> put_status(:unauthorized) |> json(%{error: "Unauthorized"})
    end
  end

  def list_organizations(conn, _params) do
    user = conn.assigns[:current_user]
    if user do
      {:ok, orgs} = Organization.list_user_organizations(user.id)
      json(conn, orgs)
    else
      conn |> put_status(:unauthorized) |> json(%{error: "Unauthorized"})
    end
  end

  def invite_member(conn, %{"organizationId" => org_id, "email" => email, "role" => role}) do
    user = conn.assigns[:current_user]
    if user do
       case Organization.invite_member(user.id, org_id, email, role) do
         {:ok, invitation} -> json(conn, invitation)
         {:error, reason} ->
            conn |> put_status(:bad_request) |> json(%{error: format_error(reason)})
       end
    else
       conn |> put_status(:unauthorized) |> json(%{error: "Unauthorized"})
    end
  end

  # --- Plugin: SSO (Client) ---

  def register_sso_provider(conn, params) do
    case SSO.register_provider(params) do
      {:ok, provider} -> json(conn, provider)
      {:error, reason} ->
         conn |> put_status(:bad_request) |> json(%{error: format_error(reason)})
    end
  end

  def sign_in_sso(conn, %{"providerId" => provider_id, "redirectUri" => redirect_uri}) do
    case SSO.sign_in_sso(provider_id, redirect_uri) do
      {:ok, url, _state} -> json(conn, %{url: url})
      {:error, reason} ->
         conn |> put_status(:bad_request) |> json(%{error: format_error(reason)})
    end
  end

  def callback_sso(conn, %{"provider_id" => provider_id, "code" => code}) do
     # Should ideally verify state too
     # redirect_uri must match what was sent
     redirect_uri = "#{base_url()}/sso/callback/#{provider_id}"
     case SSO.callback_sso(provider_id, code, redirect_uri) do
       {:ok, user, session} ->
          conn
          |> put_session_cookie(session.token)
          |> json(%{user: user, token: session.token})
       {:error, reason} ->
          conn |> put_status(:unauthorized) |> json(%{error: format_error(reason)})
     end
  end

  # --- Plugin: OIDC Provider (Server) ---

  def oidc_discovery(conn, _params) do
    json(conn, OIDCProvider.openid_configuration())
  end

  def oidc_jwks(conn, _params) do
    json(conn, OIDCProvider.jwks())
  end

  def oidc_authorize(conn, %{"client_id" => client_id, "redirect_uri" => redirect_uri, "response_type" => "code", "scope" => scope, "state" => state}) do
    user = conn.assigns[:current_user]
    if user do
       case OIDCProvider.authorize(client_id, redirect_uri, "code", scope, state, user.id) do
         {:ok, url} -> redirect(conn, external: url)
         {:error, reason} ->
            conn |> put_status(:bad_request) |> json(%{error: format_error(reason)})
       end
    else
       # If not logged in, redirect to login page with return_to
       # For API only, we return 401
       conn |> put_status(:unauthorized) |> json(%{error: "Login required"})
    end
  end

  def oidc_token(conn, %{"grant_type" => "authorization_code", "code" => code, "redirect_uri" => redirect_uri, "client_id" => client_id, "client_secret" => client_secret}) do
    case OIDCProvider.token("authorization_code", code, redirect_uri, client_id, client_secret) do
      {:ok, token_response} -> json(conn, token_response)
      {:error, reason} ->
         conn |> put_status(:bad_request) |> json(%{error: format_error(reason)})
    end
  end

  def oidc_userinfo(conn, _params) do
     # Expect Bearer token
     case get_req_header(conn, "authorization") do
       ["Bearer " <> token] ->
          case OIDCProvider.userinfo(token) do
            {:ok, info} -> json(conn, info)
            {:error, reason} -> conn |> put_status(:unauthorized) |> json(%{error: format_error(reason)})
          end
       _ -> conn |> put_status(:unauthorized) |> json(%{error: "Missing token"})
     end
  end

  # --- Helpers ---

  defp put_session_cookie(conn, token) do
    put_resp_cookie(conn, "better_auth_session_token", token, http_only: true, max_age: 30 * 24 * 3600)
  end

  defp get_session_token(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] -> token
      _ ->
        conn = fetch_cookies(conn)
        conn.cookies["better_auth_session_token"]
    end
  end

  defp format_error(%Ecto.Changeset{} = changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end

  defp format_error(reason) when is_binary(reason), do: reason
  defp format_error(reason), do: inspect(reason)
end
