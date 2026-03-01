defmodule BetterAuth.Session do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :expires_at, :token, :ip_address, :user_agent, :user_id, :inserted_at, :updated_at]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sessions" do
    field :expires_at, :utc_datetime
    field :token, :string
    field :ip_address, :string
    field :user_agent, :string

    belongs_to :user, BetterAuth.User

    timestamps()
  end

  @doc false
  def changeset(session, attrs) do
    session
    |> cast(attrs, [:expires_at, :token, :ip_address, :user_agent, :user_id])
    |> validate_required([:expires_at, :token, :user_id])
    |> unique_constraint(:token)
    |> foreign_key_constraint(:user_id)
  end
end
