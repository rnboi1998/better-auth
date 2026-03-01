defmodule BetterAuth.Invitation do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :email, :role, :status, :organization_id, :inviter_id, :expires_at, :inserted_at, :updated_at]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "invitations" do
    field :email, :string
    field :role, :string
    field :status, :string, default: "pending"
    field :expires_at, :utc_datetime

    belongs_to :organization, BetterAuth.Organization
    belongs_to :inviter, BetterAuth.User

    timestamps()
  end

  @doc false
  def changeset(invitation, attrs) do
    invitation
    |> cast(attrs, [:email, :role, :status, :expires_at, :organization_id, :inviter_id])
    |> validate_required([:email, :role, :status, :expires_at, :organization_id, :inviter_id])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must be a valid email")
    |> foreign_key_constraint(:organization_id)
    |> foreign_key_constraint(:inviter_id)
  end
end
