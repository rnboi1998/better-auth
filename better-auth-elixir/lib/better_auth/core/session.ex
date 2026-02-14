defmodule BetterAuth.Core.Session do
  alias BetterAuth.Session

  @default_expiry_days 30

  defp adapter do
    Application.get_env(:better_auth, :adapter, BetterAuth.Adapters.Ecto)
  end

  def create(user_id, opts \\ []) do
    token = :crypto.strong_rand_bytes(32) |> Base.encode64(padding: false)
    expiry = DateTime.utc_now() |> DateTime.add(@default_expiry_days * 24 * 3600, :second)

    attrs = %{
      token: token,
      expires_at: expiry,
      user_id: user_id,
      ip_address: opts[:ip_address],
      user_agent: opts[:user_agent]
    }

    adapter().create_session(attrs)
  end

  def get(token) do
    case adapter().get_session_by_token(token) do
      {:ok, nil} -> {:error, :not_found}
      {:ok, session} ->
        if DateTime.compare(session.expires_at, DateTime.utc_now()) == :gt do
          {:ok, session}
        else
          {:error, :expired}
        end
      error -> error
    end
  end

  def delete(token) do
    adapter().delete_session(token)
  end
end
