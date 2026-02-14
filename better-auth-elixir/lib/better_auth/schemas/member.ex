defmodule BetterAuth.Member do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :organization_id, :user_id, :role, :inserted_at, :updated_at]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "members" do
    field :role, :string

    belongs_to :organization, BetterAuth.Organization
    belongs_to :user, BetterAuth.User

    timestamps()
  end

  @doc false
  def changeset(member, attrs) do
    member
    |> cast(attrs, [:organization_id, :user_id, :role])
    |> validate_required([:organization_id, :user_id, :role])
    |> unique_constraint([:organization_id, :user_id])
    |> foreign_key_constraint(:organization_id)
    |> foreign_key_constraint(:user_id)
  end
end
