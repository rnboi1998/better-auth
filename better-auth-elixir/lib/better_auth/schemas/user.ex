defmodule BetterAuth.User do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :name, :email, :email_verified, :image, :username, :display_username, :two_factor_enabled, :inserted_at, :updated_at]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    field :name, :string
    field :email, :string
    field :email_verified, :boolean, default: false
    field :image, :string
    field :username, :string
    field :display_username, :string
    field :two_factor_enabled, :boolean, default: false

    has_many :sessions, BetterAuth.Session, on_delete: :delete_all
    has_many :accounts, BetterAuth.Account, on_delete: :delete_all
    has_many :members, BetterAuth.Member, on_delete: :delete_all
    has_one :two_factor, BetterAuth.TwoFactor, on_delete: :delete_all

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :email_verified, :image, :username, :display_username, :two_factor_enabled])
    |> validate_required([:name, :email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must be a valid email")
    |> unique_constraint(:email)
    |> unique_constraint(:username)
  end
end
