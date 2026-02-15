defmodule Lumina.Media.OrgTest do
  use Lumina.DataCase

  import Lumina.Fixtures

  alias Lumina.Media.Org

  describe "orgs" do
    test "creates org (admin only; creator is added as owner; more members via invite)" do
      admin = admin_fixture()
      user = user_fixture()

      {:ok, org} = Org.create("My Org", "my-org", actor: admin)

      assert org.name == "My Org"
      assert org.slug == "my-org"

      # Creator (admin) is added as owner by AddCreatorAsOwner change
      org = Ash.load!(org, :memberships, authorize?: false)
      assert length(org.memberships) == 1
      assert hd(org.memberships).user_id == admin.id
      assert hd(org.memberships).role == :owner

      # Add another owner via membership (e.g. invite flow)
      {:ok, _} =
        Lumina.Accounts.OrgMembership
        |> Ash.Changeset.for_create(:create, %{user_id: user.id, org_id: org.id, role: :owner})
        |> Ash.create(authorize?: false)

      org = Ash.load!(org, :memberships, authorize?: false)
      assert length(org.memberships) == 2
      owner_user_ids = Enum.map(org.memberships, & &1.user_id) |> Enum.sort()
      assert owner_user_ids == Enum.sort([admin.id, user.id])
    end

    test "generates slug from name when slug is blank" do
      admin = admin_fixture()

      {:ok, org} = Org.create("My New Organization", "", actor: admin)

      assert org.name == "My New Organization"
      assert org.slug == "my-new-organization"
    end

    test "slug must be unique" do
      admin = admin_fixture()

      {:ok, _org1} = Org.create("Org 1", "unique-slug", actor: admin)

      assert {:error, _} = Org.create("Org 2", "unique-slug", actor: admin)
    end

    test "only members can read org" do
      user = user_fixture()
      other_user = user_fixture()

      org = org_fixture(user, %{name: "Private Org", slug: "private-org"})

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

  describe "storage_used_bytes" do
    setup do
      user = user_fixture()
      org = org_fixture(user)
      album = album_fixture(org, user)
      %{user: user, org: org, album: album}
    end

    test "is 0 with no photos", %{org: org} do
      assert Lumina.Media.Storage.used_bytes(org.id) == 0
    end

    test "sums one photo file_size", %{user: user, org: org, album: album} do
      _photo = photo_fixture(album, user, %{file_size: 1000})
      assert Lumina.Media.Storage.used_bytes(org.id) == 1000
    end

    test "sums multiple photos", %{user: user, org: org, album: album} do
      _p1 = photo_fixture(album, user, %{file_size: 500})
      _p2 = photo_fixture(album, user, %{file_size: 1500})
      assert Lumina.Media.Storage.used_bytes(org.id) == 2000
    end

    test "decreases after photo is deleted", %{user: user, org: org, album: album} do
      photo = photo_fixture(album, user, %{file_size: 3000})
      assert Lumina.Media.Storage.used_bytes(org.id) == 3000

      Ash.destroy(photo, actor: user, tenant: org.id)
      assert Lumina.Media.Storage.used_bytes(org.id) == 0
    end
  end
end
