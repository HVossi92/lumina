defmodule Lumina.Media.PhotoTest do
  use Lumina.DataCase

  import Lumina.Fixtures

  alias Lumina.Media.Photo

  describe "photos" do
    setup do
      user = user_fixture()
      org = org_fixture(user)
      album = album_fixture(org, user)

      %{user: user, org: org, album: album}
    end

    test "creates photo in album", %{user: user, album: album} do
      photo = photo_fixture(album, user, %{filename: "test.jpg"})

      assert photo.filename == "test.jpg"
      assert photo.album_id == album.id
      assert photo.uploaded_by_id == user.id
    end

    test "photo inherits org_id from album", %{user: user, album: album, org: org} do
      photo = photo_fixture(album, user)

      assert photo.org_id == org.id
    end

    test "lists photos for album", %{user: user, org: org, album: album} do
      photo1 = photo_fixture(album, user, %{filename: "photo1.jpg"})
      photo2 = photo_fixture(album, user, %{filename: "photo2.jpg"})

      photos = Photo.for_album!(album.id, actor: user, tenant: org.id)

      assert length(photos) == 2
      photo_ids = Enum.map(photos, & &1.id)
      assert photo1.id in photo_ids
      assert photo2.id in photo_ids
    end

    test "adds tags to photo", %{user: user, org: org, album: album} do
      photo = photo_fixture(album, user)

      {:ok, updated} =
        photo
        |> Ash.Changeset.for_update(:add_tags, %{tags: ["sunset", "beach"]})
        |> Ash.update(actor: user, tenant: org.id)

      assert "sunset" in updated.tags
      assert "beach" in updated.tags
    end

    test "add_tags replaces existing tags", %{user: user, org: org, album: album} do
      photo = photo_fixture(album, user, %{tags: ["old1", "old2"]})

      {:ok, updated} =
        photo
        |> Ash.Changeset.for_update(:add_tags, %{tags: ["new1", "new2"]})
        |> Ash.update(actor: user, tenant: org.id)

      assert updated.tags == ["new1", "new2"]
    end

    test "add_tags with empty array clears tags", %{user: user, org: org, album: album} do
      photo = photo_fixture(album, user, %{tags: ["a", "b"]})

      {:ok, updated} =
        photo
        |> Ash.Changeset.for_update(:add_tags, %{tags: []})
        |> Ash.update(actor: user, tenant: org.id)

      assert updated.tags == []
    end

    test "add_tags stores duplicate values as given", %{user: user, org: org, album: album} do
      photo = photo_fixture(album, user)

      {:ok, updated} =
        photo
        |> Ash.Changeset.for_update(:add_tags, %{tags: ["beach", "beach", "Beach"]})
        |> Ash.update(actor: user, tenant: org.id)

      assert Enum.sort(updated.tags) == ["Beach", "beach", "beach"]
    end

    test "renames photo", %{user: user, org: org, album: album} do
      photo = photo_fixture(album, user, %{filename: "original.jpg"})

      {:ok, updated} =
        photo
        |> Ash.Changeset.for_update(:rename, %{filename: "holiday-2024.jpg"})
        |> Ash.update(actor: user, tenant: org.id)

      assert updated.filename == "holiday-2024.jpg"
    end

    test "rename validates presence of filename", %{user: user, org: org, album: album} do
      photo = photo_fixture(album, user, %{filename: "original.jpg"})

      assert {:error, _} =
               photo
               |> Ash.Changeset.for_update(:rename, %{filename: ""})
               |> Ash.update(actor: user, tenant: org.id)
    end

    test "only org members can view photos", %{user: user, org: org, album: album} do
      photo = photo_fixture(album, user)
      other_user = user_fixture()

      # Member can read
      assert {:ok, _} = Ash.get(Photo, photo.id, actor: user, tenant: org.id)

      # Non-member cannot read (returns NotFound due to filter-based policies)
      assert {:error, %Ash.Error.Invalid{}} =
               Ash.get(Photo, photo.id, actor: other_user, tenant: org.id)
    end

    test "deletes photo", %{user: user, org: org, album: album} do
      photo = photo_fixture(album, user)

      assert :ok = Ash.destroy(photo, actor: user, tenant: org.id)
      assert {:error, _} = Ash.get(Photo, photo.id, actor: user, tenant: org.id)
    end
  end
end
