defmodule Lumina.Media.ShareLinkTest do
  use Lumina.DataCase

  import Lumina.Fixtures

  alias Lumina.Media.ShareLink

  describe "share links" do
    setup do
      user = user_fixture()
      org = org_fixture(user)
      album = album_fixture(org, user)

      %{user: user, org: org, album: album}
    end

    test "creates share link for album", %{user: user, album: album} do
      share_link = share_link_fixture(album, user)

      assert share_link.album_id == album.id
      assert share_link.created_by_id == user.id
      assert is_binary(share_link.token)
      refute is_nil(share_link.expires_at)
    end

    test "generates unique token", %{user: user, album: album} do
      link1 = share_link_fixture(album, user)
      link2 = share_link_fixture(album, user)

      assert link1.token != link2.token
    end

    test "retrieves share link by token", %{user: user, album: album} do
      share_link = share_link_fixture(album, user)

      {:ok, found} = ShareLink.by_token(share_link.token)

      assert found.id == share_link.id
    end

    test "creates password-protected share link", %{user: user, album: album} do
      share_link = share_link_fixture(album, user, %{password: "secret123"})

      assert !is_nil(share_link.password_hash)
      assert Bcrypt.verify_pass("secret123", share_link.password_hash)
    end

    test "increments view count", %{user: user, album: album} do
      share_link = share_link_fixture(album, user)

      assert share_link.view_count == 0

      {:ok, updated} =
        share_link
        |> Ash.Changeset.for_update(:increment_view_count)
        |> Ash.update()

      assert updated.view_count == 1
    end

    test "public can read share links without auth", %{user: user, album: album} do
      share_link = share_link_fixture(album, user)

      # Anyone can read by token (no actor)
      {:ok, found} = ShareLink.by_token(share_link.token)

      assert found.id == share_link.id
    end

    test "authenticated users can create share links", %{user: user, org: org, album: album} do
      # Org member can create
      {:ok, link} =
        ShareLink
        |> Ash.Changeset.for_create(:create, %{
          expires_at: DateTime.utc_now() |> DateTime.add(7, :day),
          album_id: album.id,
          created_by_id: user.id
        })
        |> Ash.create(actor: user, tenant: org.id)

      assert link.album_id == album.id
    end

    test "anonymous users cannot create share links", %{org: org, album: album} do
      # No actor (anonymous) cannot create
      assert {:error, %Ash.Error.Forbidden{}} =
               ShareLink
               |> Ash.Changeset.for_create(:create, %{
                 expires_at: DateTime.utc_now() |> DateTime.add(7, :day),
                 album_id: album.id,
                 created_by_id: nil
               })
               |> Ash.create(tenant: org.id)
    end
  end
end
