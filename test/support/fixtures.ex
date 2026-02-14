defmodule Lumina.Fixtures do
  @moduledoc """
  Test fixtures for Lumina tests.
  """

  alias Lumina.Accounts.User
  alias Lumina.Media.{Org, Album, Photo, ShareLink}

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      User
      |> Ash.Changeset.for_create(:register_with_password, %{
        email: attrs[:email] || "user#{System.unique_integer()}@example.com",
        password: attrs[:password] || "Password123!",
        password_confirmation: attrs[:password] || "Password123!"
      })
      |> Ash.create(authorize?: false)

    user
  end

  def org_fixture(owner, attrs \\ %{}) do
    {:ok, org} =
      Org.create(
        attrs[:name] || "Test Org #{System.unique_integer()}",
        attrs[:slug] || "test-org-#{System.unique_integer()}",
        owner.id,
        actor: owner
      )

    org
  end

  def album_fixture(org, user, attrs \\ %{}) do
    {:ok, album} =
      Album.create(
        attrs[:name] || "Test Album #{System.unique_integer()}",
        org.id,
        actor: user,
        tenant: org.id
      )

    if attrs[:description] do
      {:ok, album} =
        album
        |> Ash.Changeset.for_update(:update, %{description: attrs[:description]})
        |> Ash.update(actor: user, tenant: org.id)

      album
    else
      album
    end
  end

  def photo_fixture(album, user, attrs \\ %{}) do
    photo_id = Ash.UUID.generate()
    filename = attrs[:filename] || "test-photo-#{System.unique_integer()}.jpg"

    {:ok, photo} =
      Photo
      |> Ash.Changeset.for_create(:create, %{
        filename: filename,
        original_path: attrs[:original_path] || "priv/static/uploads/originals/#{photo_id}.jpg",
        thumbnail_path:
          attrs[:thumbnail_path] || "priv/static/uploads/thumbnails/#{photo_id}.jpg",
        file_size: attrs[:file_size] || 1024,
        content_type: attrs[:content_type] || "image/jpeg",
        tags: attrs[:tags] || [],
        album_id: album.id,
        uploaded_by_id: user.id
      })
      |> Ash.create(actor: user, tenant: album.org_id)

    photo
  end

  def share_link_fixture(album, user, attrs \\ %{}) do
    expires_at = attrs[:expires_at] || DateTime.utc_now() |> DateTime.add(7, :day)

    password_hash =
      if attrs[:password] do
        Bcrypt.hash_pwd_salt(attrs[:password])
      else
        nil
      end

    {:ok, share_link} =
      ShareLink
      |> Ash.Changeset.for_create(:create, %{
        expires_at: expires_at,
        password_hash: password_hash,
        album_id: album.id,
        created_by_id: user.id,
        max_views: attrs[:max_views]
      })
      |> Ash.create(actor: user, tenant: album.org_id)

    share_link
  end
end
