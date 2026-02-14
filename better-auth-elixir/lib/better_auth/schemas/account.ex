defmodule BetterAuth.Account do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :provider_id, :account_id, :user_id, :scope, :access_token_expires_at, :refresh_token_expires_at, :inserted_at, :updated_at]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "accounts" do
    field :provider_id, :string
    field :account_id, :string
    field :access_token, :string
    field :refresh_token, :string
    field :id_token, :string
    field :access_token_expires_at, :utc_datetime
    field :refresh_token_expires_at, :utc_datetime
    field :scope, :string
    field :password, :string # This should be hashed for credential provider

    belongs_to :user, BetterAuth.User

    timestamps()
  end

  @doc false
  def changeset(account, attrs) do
    account
    |> cast(attrs, [:provider_id, :account_id, :user_id, :access_token, :refresh_token, :id_token, :access_token_expires_at, :refresh_token_expires_at, :scope, :password])
    |> validate_required([:provider_id, :account_id, :user_id])
    |> foreign_key_constraint(:user_id)
  end
end
