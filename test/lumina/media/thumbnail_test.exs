defmodule Lumina.Media.ThumbnailTest do
  use Lumina.DataCase

  alias Lumina.Media.Thumbnail

  describe "thumbnail generation" do
    test "uploads_root returns app priv path" do
      root = Thumbnail.uploads_root()
      assert root =~ "priv/static/uploads"
      assert File.dir?(root) or not File.exists?(root)
    end

    test "thumbnail_path generates absolute path under uploads_root" do
      photo_id = Ash.UUID.generate()
      filename = "photo.jpg"

      path = Thumbnail.thumbnail_path(photo_id, filename)

      assert path == Path.join([Thumbnail.uploads_root(), "thumbnails", "#{photo_id}.avif"])
      assert path =~ "priv/static/uploads/thumbnails/#{photo_id}.avif"
    end

    test "original_path generates absolute path under uploads_root" do
      photo_id = Ash.UUID.generate()
      filename = "photo.jpg"

      path = Thumbnail.original_path(photo_id, filename)

      assert path == Path.join([Thumbnail.uploads_root(), "originals", "#{photo_id}.jpg"])
      assert path =~ "priv/static/uploads/originals/#{photo_id}.jpg"
    end

    test "thumbnail_url_from_path converts absolute path to /uploads/ URL" do
      photo_id = Ash.UUID.generate()
      abs_path = Path.join([Thumbnail.uploads_root(), "thumbnails", "#{photo_id}.avif"])

      assert Thumbnail.thumbnail_url_from_path(abs_path) == "/uploads/thumbnails/#{photo_id}.avif"
    end

    test "original_url_from_path converts absolute path to /uploads/ URL" do
      photo_id = Ash.UUID.generate()
      abs_path = Path.join([Thumbnail.uploads_root(), "originals", "#{photo_id}.png"])

      assert Thumbnail.original_url_from_path(abs_path) == "/uploads/originals/#{photo_id}.png"
    end

    test "thumbnail_url generates correct URL" do
      photo_id = Ash.UUID.generate()
      filename = "photo.jpg"

      url = Thumbnail.thumbnail_url(photo_id, filename)

      assert url == "/uploads/thumbnails/#{photo_id}.avif"
    end

    test "original_url generates correct URL" do
      photo_id = Ash.UUID.generate()
      filename = "photo.jpg"

      url = Thumbnail.original_url(photo_id, filename)

      assert url == "/uploads/originals/#{photo_id}.jpg"
    end
  end
end
