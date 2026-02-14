defmodule Lumina.Media.OrgTest do
  use Lumina.DataCase

  import Lumina.Fixtures

  alias Lumina.Media.Org

  describe "orgs" do
    test "creates org with owner membership" do
      user = user_fixture()

      {:ok, org} = Org.create("My Org", "my-org", user.id, actor: user)

      assert org.name == "My Org"
      assert org.slug == "my-org"

      # Verify owner membership was created
      org = Ash.load!(org, :memberships, authorize?: false)
      assert length(org.memberships) == 1
      assert hd(org.memberships).user_id == user.id
      assert hd(org.memberships).role == :owner
    end

    test "slug must be unique" do
      user = user_fixture()

      {:ok, _org1} = Org.create("Org 1", "unique-slug", user.id, actor: user)

      assert {:error, _} = Org.create("Org 2", "unique-slug", user.id, actor: user)
    end

    test "only members can read org" do
      user = user_fixture()
      other_user = user_fixture()

      {:ok, org} = Org.create("Private Org", "private-org", user.id, actor: user)

      # Owner can read
      assert {:ok, _} = Ash.get(Org, org.id, actor: user)

      # Non-member cannot read (returns NotFound due to filter-based policies)
      assert {:error, %Ash.Error.Invalid{}} = Ash.get(Org, org.id, actor: other_user)
    end

    test "only owners can update org" do
      owner = user_fixture()
      member = user_fixture()

      org = org_fixture(owner)

      # Add member
      Lumina.Accounts.OrgMembership
      |> Ash.Changeset.for_create(:create, %{
        user_id: member.id,
        org_id: org.id,
        role: :member
      })
      |> Ash.create(actor: owner)

      # Owner can update
      {:ok, updated} =
        org
        |> Ash.Changeset.for_update(:update, %{name: "Updated Name"})
        |> Ash.update(actor: owner)

      assert updated.name == "Updated Name"

      # Member cannot update (returns StaleRecord due to filter-based policies)
      assert {:error, _} =
               org
               |> Ash.Changeset.for_update(:update, %{name: "Another Name"})
               |> Ash.update(actor: member)
    end

    test "for_user returns user's orgs" do
      user = user_fixture()
      other_user = user_fixture()

      org1 = org_fixture(user)
      _org2 = org_fixture(other_user)

      orgs = Org.for_user!(user.id, actor: user)

      assert length(orgs) == 1
      assert hd(orgs).id == org1.id
    end

    test "by_slug retrieves org by slug" do
      user = user_fixture()
      org = org_fixture(user, %{slug: "test-slug-123"})

      {:ok, found_org} = Org.by_slug("test-slug-123", actor: user)

      assert found_org.id == org.id
    end
  end
end
