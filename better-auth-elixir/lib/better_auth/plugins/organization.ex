defmodule BetterAuth.Plugins.Organization do
  @moduledoc """
  Plugin for Organization management.
  """
  alias BetterAuth.{User, Organization, Member, Invitation}
  import Ecto.Query

  defp repo do
    Application.get_env(:better_auth, :repo) || raise "BetterAuth repo not configured"
  end

  def create(user_id, name, slug) do
    # Create Organization
    case %Organization{}
         |> Organization.changeset(%{name: name, slug: slug})
         |> repo().insert() do
      {:ok, org} ->
        # Add creator as owner
        %Member{}
        |> Member.changeset(%{organization_id: org.id, user_id: user_id, role: "owner"})
        |> repo().insert()

        {:ok, org}

      error -> error
    end
  end

  def list_user_organizations(user_id) do
    query = from m in Member,
            join: o in Organization, on: m.organization_id == o.id,
            where: m.user_id == ^user_id,
            select: o

    {:ok, repo().all(query)}
  end

  def invite_member(inviter_id, org_id, email, role) do
     # Check permissions (omitted for brevity)
     %Invitation{}
     |> Invitation.changeset(%{
          organization_id: org_id,
          inviter_id: inviter_id,
          email: email,
          role: role,
          expires_at: DateTime.utc_now() |> DateTime.add(7 * 24 * 3600, :second)
        })
     |> repo().insert()
  end
end
