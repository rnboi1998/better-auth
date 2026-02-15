defmodule BetterAuth.SSOProvider do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :provider_id, :issuer, :domain, :user_id, :inserted_at, :updated_at]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sso_providers" do
    field :provider_id, :string
    field :issuer, :string
    field :domain, :string
    field :oidc_config, :map
    field :saml_config, :map

    belongs_to :user, BetterAuth.User

    timestamps()
  end

  @doc false
  def changeset(sso_provider, attrs) do
    sso_provider
    |> cast(attrs, [:provider_id, :issuer, :domain, :oidc_config, :saml_config, :user_id])
    |> validate_required([:provider_id, :issuer, :domain])
    |> unique_constraint(:provider_id)
    |> foreign_key_constraint(:user_id)
  end
end
