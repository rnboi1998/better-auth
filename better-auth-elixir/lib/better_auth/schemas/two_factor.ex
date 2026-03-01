defmodule BetterAuth.TwoFactor do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :secret, :user_id, :backup_codes, :inserted_at, :updated_at]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "two_factors" do
    field :secret, :string
    field :backup_codes, :string # Comma separated or encrypted string

    belongs_to :user, BetterAuth.User

    timestamps()
  end

  @doc false
  def changeset(two_factor, attrs) do
    two_factor
    |> cast(attrs, [:secret, :backup_codes, :user_id])
    |> validate_required([:secret, :backup_codes, :user_id])
    |> foreign_key_constraint(:user_id)
  end
end
