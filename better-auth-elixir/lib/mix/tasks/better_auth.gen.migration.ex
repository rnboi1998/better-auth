defmodule Mix.Tasks.BetterAuth.Gen.Migration do
  use Mix.Task

  import Mix.Generator

  @shortdoc "Generates BetterAuth migration file"

  def run(args) do
    if Mix.Project.umbrella?() do
      Mix.raise("mix better_auth.gen.migration can only be run inside an application directory")
    end

    repo = args |> List.first() || Mix.raise("expected repo as argument")

    path = "priv/repo/migrations"
    file = Path.join(path, "#{timestamp()}_create_better_auth_tables.exs")
    create_directory(path)

    create_file(file, migration_template(repo: repo))
  end

  defp timestamp do
    {{y, m, d}, {hh, mm, ss}} = :calendar.universal_time()
    "#{y}#{pad(m)}#{pad(d)}#{pad(hh)}#{pad(mm)}#{pad(ss)}"
  end

  defp pad(i) when i < 10, do: "0#{i}"
  defp pad(i), do: "#{i}"

  defp migration_template(opts) do
    """
    defmodule #{opts[:repo]}.Migrations.CreateBetterAuthTables do
      use Ecto.Migration

      def change do
        create table(:users, primary_key: false) do
          add :id, :binary_id, primary_key: true
          add :name, :string, null: false
          add :email, :string, null: false
          add :email_verified, :boolean, default: false, null: false
          add :image, :string

          timestamps()
        end

        create unique_index(:users, [:email])

        create table(:sessions, primary_key: false) do
          add :id, :binary_id, primary_key: true
          add :expires_at, :utc_datetime, null: false
          add :token, :string, null: false
          add :ip_address, :string
          add :user_agent, :string
          add :user_id, references(:users, on_delete: :delete_all, type: :binary_id), null: false

          timestamps()
        end

        create unique_index(:sessions, [:token])

        create table(:accounts, primary_key: false) do
          add :id, :binary_id, primary_key: true
          add :provider_id, :string, null: false
          add :account_id, :string, null: false
          add :user_id, references(:users, on_delete: :delete_all, type: :binary_id), null: false
          add :access_token, :text
          add :refresh_token, :text
          add :id_token, :text
          add :access_token_expires_at, :utc_datetime
          add :refresh_token_expires_at, :utc_datetime
          add :scope, :text
          add :password, :text

          timestamps()
        end

        create table(:verifications, primary_key: false) do
          add :id, :binary_id, primary_key: true
          add :identifier, :string, null: false
          add :value, :string, null: false
          add :expires_at, :utc_datetime, null: false

          timestamps()
        end
      end
    end
    """
  end
end
