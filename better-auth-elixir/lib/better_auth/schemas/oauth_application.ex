defmodule BetterAuth.OAuthApplication do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :client_id, :name, :icon, :metadata, :redirect_urls, :type, :inserted_at, :updated_at]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "oauth_applications" do
    field :client_id, :string
    field :client_secret, :string
    field :name, :string
    field :icon, :string
    field :metadata, :string
    field :redirect_urls, :string # Comma separated
    field :type, :string # web, native, etc.
    field :disabled, :boolean, default: false

    belongs_to :user, BetterAuth.User

    timestamps()
  end

  @doc false
  def changeset(app, attrs) do
    app
    |> cast(attrs, [:client_id, :client_secret, :name, :icon, :metadata, :redirect_urls, :type, :disabled, :user_id])
    |> validate_required([:client_id, :name, :type, :redirect_urls])
    |> unique_constraint(:client_id)
    |> foreign_key_constraint(:user_id)
  end
end
