defmodule BetterAuth.Plugins.OIDCProvider do
  @moduledoc """
  Plugin to make BetterAuth an OIDC Provider.
  """
  alias BetterAuth.{User, OAuthApplication, OAuthAccessToken, OAuthConsent}
  import Ecto.Query
  alias Joken.Signer

  defp repo do
    Application.get_env(:better_auth, :repo) || raise "BetterAuth repo not configured"
  end

  defp base_url do
    Application.get_env(:better_auth, :base_url) || "http://localhost:4000/api/auth"
  end

  defp secret_key_base do
    Application.get_env(:better_auth, :secret_key_base) || raise "BetterAuth secret_key_base not configured"
  end

  defp oidc_signing_key do
     Application.get_env(:better_auth, :oidc_signing_key) || raise "BetterAuth :oidc_signing_key config required (map with 'pem', 'kid', 'n', 'e')"
  end

  # --- Discovery ---
  def openid_configuration do
    %{
      issuer: base_url(),
      authorization_endpoint: "#{base_url()}/oauth2/authorize",
      token_endpoint: "#{base_url()}/oauth2/token",
      userinfo_endpoint: "#{base_url()}/oauth2/userinfo",
      jwks_uri: "#{base_url()}/jwks.json",
      scopes_supported: ["openid", "email", "profile"],
      response_types_supported: ["code"],
      subject_types_supported: ["public"],
      id_token_signing_alg_values_supported: ["RS256"]
    }
  end

  # --- JWKS ---
  def jwks do
    key = oidc_signing_key()
    %{
      keys: [
        %{
          kty: "RSA",
          use: "sig",
          kid: key["kid"] || "better-auth-key-1",
          alg: "RS256",
          n: key["n"], # modulus
          e: key["e"]  # exponent
        }
      ]
    }
  end

  # --- Authorization ---
  def authorize(client_id, redirect_uri, response_type, scope, state, user_id) do
    client = repo().get_by(OAuthApplication, client_id: client_id)

    if client && client.redirect_urls && String.contains?(client.redirect_urls, redirect_uri) do
      # Create Authorization Code (stateless for demo)
      signer = Joken.Signer.create("HS256", secret_key_base())
      claims = %{
        "sub" => user_id,
        "client_id" => client_id,
        "redirect_uri" => redirect_uri,
        "scope" => scope,
        "exp" => Joken.current_time() + 600 # 10 mins
      }
      {:ok, code, _} = Joken.generate_and_sign(%{}, claims, signer)

      redirect_url = "#{redirect_uri}?code=#{code}&state=#{state}"
      {:ok, redirect_url}
    else
      {:error, :invalid_client_or_redirect}
    end
  end

  # --- Token ---
  def token(grant_type, code, redirect_uri, client_id, client_secret) do
    # Verify Client
    client = repo().get_by(OAuthApplication, client_id: client_id)
    if client && client.client_secret == client_secret do
       # Verify Code
       signer = Joken.Signer.create("HS256", secret_key_base())
       case Joken.verify(code, signer) do
         {:ok, claims} ->
            if claims["redirect_uri"] == redirect_uri do
               # Generate Access Token & ID Token
               user = repo().get(User, claims["sub"])

               # ID Token Signing
               key = oidc_signing_key()
               signer_rs256 = Joken.Signer.create("RS256", %{"pem" => key["pem"]})

               id_token_claims = %{
                 "iss" => base_url(),
                 "sub" => user.id,
                 "aud" => client_id,
                 "email" => user.email,
                 "email_verified" => user.email_verified,
                 "name" => user.name,
                 "iat" => Joken.current_time(),
                 "exp" => Joken.current_time() + 3600,
                 "kid" => key["kid"] || "better-auth-key-1"
               }

               {:ok, id_token, _} = Joken.generate_and_sign(%{}, id_token_claims, signer_rs256)

               access_token = Base.encode64(:crypto.strong_rand_bytes(32))
               refresh_token = Base.encode64(:crypto.strong_rand_bytes(32))

               # Store Access Token
               repo().insert(%OAuthAccessToken{
                 access_token: access_token,
                 refresh_token: refresh_token,
                 expires_at: DateTime.utc_now() |> DateTime.add(3600, :second),
                 client_id: client_id,
                 user_id: user.id,
                 scopes: claims["scope"]
               })

               {:ok, %{
                 access_token: access_token,
                 token_type: "Bearer",
                 expires_in: 3600,
                 refresh_token: refresh_token,
                 id_token: id_token
               }}
            else
               {:error, :invalid_grant}
            end
         _ -> {:error, :invalid_code}
       end
    else
       {:error, :invalid_client}
    end
  end

  # --- UserInfo ---
  def userinfo(access_token) do
    token = repo().get_by(OAuthAccessToken, access_token: access_token) |> repo().preload(:user)
    if token && DateTime.compare(token.expires_at, DateTime.utc_now()) == :gt do
      user = token.user
      {:ok, %{
        sub: user.id,
        name: user.name,
        email: user.email,
        email_verified: user.email_verified,
        picture: user.image
      }}
    else
      {:error, :invalid_token}
    end
  end
end
