defmodule BetterAuth.Web.Plug do
  @moduledoc """
  A Plug to verify the session token.
  """
  import Plug.Conn
  alias BetterAuth.Core.Session

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_session_token(conn) do
      nil ->
        assign(conn, :current_user, nil)

      token ->
        case Session.get(token) do
          {:ok, session} ->
            assign(conn, :current_user, session.user)
            |> assign(:session_token, token)

          {:error, _} ->
            assign(conn, :current_user, nil)
        end
    end
  end

  defp get_session_token(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] -> token
      _ ->
        conn = fetch_cookies(conn)
        conn.cookies["better_auth_session_token"]
    end
  end
end
