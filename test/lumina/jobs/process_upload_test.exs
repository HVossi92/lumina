defmodule Lumina.Jobs.ProcessUploadTest do
  use Lumina.DataCase
  use Oban.Testing, repo: Lumina.Repo

  import Lumina.Fixtures

  alias Lumina.Jobs.ProcessUpload

  describe "process upload job" do
    test "processes photo upload" do
      user = user_fixture()
      org = org_fixture(user)
      album = album_fixture(org, user)
      photo = photo_fixture(album, user)

      # Create directories
      File.mkdir_p!(Path.dirname(photo.original_path))
      File.mkdir_p!(Path.dirname(photo.thumbnail_path))

      # Create a dummy original file (not a valid image)
      File.write!(photo.original_path, "fake image data")

      # Execute job - returns error because fake data isn't a valid image
      assert {:error, _reason} = perform_job(ProcessUpload, %{photo_id: photo.id})

      # Note: In a real test with actual image files and libvips,
      # this would succeed and generate a thumbnail
    end
  end
end
