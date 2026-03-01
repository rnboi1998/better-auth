defmodule BetterAuth.OAuthAccessToken do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :access_token, :expires_at, :scopes, :client_id, :user_id, :inserted_at, :updated_at]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "oauth_access_tokens" do
    field :access_token, :string
    field :refresh_token, :string
    field :expires_at, :utc_datetime
    field :refresh_token_expires_at, :utc_datetime
    field :scopes, :string

    # client_id here is the OAuthApplication.client_id, NOT the binary id
    field :client_id, :string
    belongs_to :user, BetterAuth.User

    timestamps()
  end

  @doc false
  def changeset(token, attrs) do
    token
    |> cast(attrs, [:access_token, :refresh_token, :expires_at, :refresh_token_expires_at, :scopes, :client_id, :user_id])
    |> validate_required([:access_token, :client_id, :scopes])
    |> unique_constraint(:access_token)
    |> unique_constraint(:refresh_token)
    |> foreign_key_constraint(:user_id)
    # Note: client_id might not be a foreign key in database level if it's a string ID, but logic should enforce it
  end
end
