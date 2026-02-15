defmodule Lumina.Media.Org.AddCreatorAsOwner do
  @moduledoc """
  Ash change: after creating an org, creates an OrgMembership for the actor as :owner
  so the creator can access the org (e.g. after redirect from org creation).
  """
  use Ash.Resource.Change

  @impl true
  def change(changeset, _opts, _context) do
    actor = get_in(changeset.context, [:private, :actor])

    if actor do
      Ash.Changeset.after_action(changeset, fn _changeset, org ->
        Lumina.Accounts.OrgMembership
        |> Ash.Changeset.for_create(:create, %{
          user_id: actor.id,
          org_id: org.id,
          role: :owner
        })
        |> Ash.create(authorize?: false)

        {:ok, org}
      end)
    else
      changeset
    end
  end
end
