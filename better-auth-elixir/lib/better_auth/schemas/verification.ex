defmodule BetterAuth.Verification do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :identifier, :value, :expires_at, :inserted_at, :updated_at]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "verifications" do
    field :identifier, :string
    field :value, :string
    field :expires_at, :utc_datetime

    timestamps()
  end

  @doc false
  def changeset(verification, attrs) do
    verification
    |> cast(attrs, [:identifier, :value, :expires_at])
    |> validate_required([:identifier, :value, :expires_at])
  end
end
