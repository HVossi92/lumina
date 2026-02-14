defmodule Lumina.Accounts.OrgMembershipTest do
  use Lumina.DataCase

  import Lumina.Fixtures

  alias Lumina.Accounts.OrgMembership

  describe "org memberships" do
    setup do
      owner = user_fixture()
      member = user_fixture()
      org = org_fixture(owner)

      %{owner: owner, member: member, org: org}
    end

    test "owner can add member to org", %{owner: owner, member: member, org: org} do
      {:ok, membership} =
        OrgMembership
        |> Ash.Changeset.for_create(:create, %{
          user_id: member.id,
          org_id: org.id,
          role: :member
        })
        |> Ash.create(actor: owner)

      assert membership.user_id == member.id
      assert membership.org_id == org.id
      assert membership.role == :member
    end

    test "prevents duplicate memberships", %{owner: owner, member: member, org: org} do
      # Create first membership
      {:ok, _} =
        OrgMembership
        |> Ash.Changeset.for_create(:create, %{
          user_id: member.id,
          org_id: org.id,
          role: :member
        })
        |> Ash.create(actor: owner)

      # Try to create duplicate
      assert {:error, _} =
               OrgMembership
               |> Ash.Changeset.for_create(:create, %{
                 user_id: member.id,
                 org_id: org.id,
                 role: :member
               })
               |> Ash.create(actor: owner)
    end

    test "users can read their own memberships", %{member: member, org: org, owner: owner} do
      {:ok, membership} =
        OrgMembership
        |> Ash.Changeset.for_create(:create, %{
          user_id: member.id,
          org_id: org.id,
          role: :member
        })
        |> Ash.create(actor: owner)

      memberships = Ash.read!(OrgMembership, actor: member)
      assert Enum.any?(memberships, &(&1.id == membership.id))
    end
  end
end
