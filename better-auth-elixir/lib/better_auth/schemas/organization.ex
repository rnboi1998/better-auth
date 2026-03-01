defmodule BetterAuth.Organization do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :name, :slug, :logo, :metadata, :inserted_at, :updated_at]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "organizations" do
    field :name, :string
    field :slug, :string
    field :logo, :string
    field :metadata, :map

    has_many :members, BetterAuth.Member, on_delete: :delete_all
    has_many :invitations, BetterAuth.Invitation, on_delete: :delete_all

    timestamps()
  end

  @doc false
  def changeset(organization, attrs) do
    organization
    |> cast(attrs, [:name, :slug, :logo, :metadata])
    |> validate_required([:name, :slug])
    |> unique_constraint(:slug)
  end
end
