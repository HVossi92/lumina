defmodule Lumina.Media.AlbumTest do
  use Lumina.DataCase

  import Lumina.Fixtures

  alias Lumina.Media.Album

  describe "albums" do
    setup do
      user = user_fixture()
      org = org_fixture(user)

      %{user: user, org: org}
    end

    test "creates album in org", %{user: user, org: org} do
      {:ok, album} = Album.create("My Album", org.id, actor: user, tenant: org.id)

      assert album.name == "My Album"
      assert album.org_id == org.id
    end

    test "lists albums for org", %{user: user, org: org} do
      album1 = album_fixture(org, user, %{name: "Album 1"})
      album2 = album_fixture(org, user, %{name: "Album 2"})

      albums = Album.for_org!(org.id, actor: user, tenant: org.id)

      assert length(albums) == 2
      album_ids = Enum.map(albums, & &1.id)
      assert album1.id in album_ids
      assert album2.id in album_ids
    end

    test "only org members can read albums", %{user: user, org: org} do
      album = album_fixture(org, user)
      other_user = user_fixture()

      # Member can read
      assert {:ok, _} = Ash.get(Album, album.id, actor: user, tenant: org.id)

      # Non-member cannot read (returns NotFound due to filter-based policies)
      assert {:error, %Ash.Error.Invalid{}} =
               Ash.get(Album, album.id, actor: other_user, tenant: org.id)
    end

    test "updates album with description", %{user: user, org: org} do
      album = album_fixture(org, user)

      {:ok, updated} =
        album
        |> Ash.Changeset.for_update(:update, %{description: "Updated description"})
        |> Ash.update(actor: user, tenant: org.id)

      assert updated.description == "Updated description"
    end

    test "deletes album", %{user: user, org: org} do
      album = album_fixture(org, user)

      assert :ok = Ash.destroy(album, actor: user, tenant: org.id)
      assert {:error, _} = Ash.get(Album, album.id, actor: user, tenant: org.id)
    end
  end
end
