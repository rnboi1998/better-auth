defmodule BetterAuth.OAuthConsent do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :client_id, :user_id, :scopes, :consent_given, :inserted_at, :updated_at]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "oauth_consents" do
    field :client_id, :string
    field :scopes, :string
    field :consent_given, :boolean, default: false

    belongs_to :user, BetterAuth.User

    timestamps()
  end

  @doc false
  def changeset(consent, attrs) do
    consent
    |> cast(attrs, [:client_id, :user_id, :scopes, :consent_given])
    |> validate_required([:client_id, :user_id, :scopes])
    |> foreign_key_constraint(:user_id)
  end
end
