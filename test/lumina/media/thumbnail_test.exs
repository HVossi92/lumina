defmodule Lumina.Media.ThumbnailTest do
  use Lumina.DataCase

  alias Lumina.Media.Thumbnail

  describe "thumbnail generation" do
    test "thumbnail_path generates correct path" do
      photo_id = Ash.UUID.generate()
      filename = "photo.jpg"

      path = Thumbnail.thumbnail_path(photo_id, filename)

      assert path =~ "priv/static/uploads/thumbnails/#{photo_id}.jpg"
    end

    test "original_path generates correct path" do
      photo_id = Ash.UUID.generate()
      filename = "photo.jpg"

      path = Thumbnail.original_path(photo_id, filename)

      assert path =~ "priv/static/uploads/originals/#{photo_id}.jpg"
    end

    test "thumbnail_url generates correct URL" do
      photo_id = Ash.UUID.generate()
      filename = "photo.jpg"

      url = Thumbnail.thumbnail_url(photo_id, filename)

      assert url == "/uploads/thumbnails/#{photo_id}.jpg"
    end

    test "original_url generates correct URL" do
      photo_id = Ash.UUID.generate()
      filename = "photo.jpg"

      url = Thumbnail.original_url(photo_id, filename)

      assert url == "/uploads/originals/#{photo_id}.jpg"
    end
  end
end
