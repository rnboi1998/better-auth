defmodule BetterAuth.Web.Controller do
  use Phoenix.Controller, namespace: BetterAuth.Web
  import Plug.Conn

  alias BetterAuth

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
