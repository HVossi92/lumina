defmodule Lumina.Media.Photo.Changes.ValidateStorageLimit do
  @moduledoc """
  Ash change: prevents creating a photo when the org's storage would exceed the 4 GB limit.
  """
  use Ash.Resource.Change

  @storage_limit_message "Organization storage limit (4 GB) would be exceeded"

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.before_action(changeset, fn changeset ->
      org_id =
        changeset.tenant ||
          case Ash.Changeset.get_attribute(changeset, :album_id) do
            nil -> nil
            album_id -> Lumina.Repo.get!(Lumina.Media.Album, album_id).org_id
          end

      if is_nil(org_id) do
        changeset
      else
        file_size = Ash.Changeset.get_attribute(changeset, :file_size) || 0
        current = Lumina.Media.Storage.used_bytes(org_id)
        limit = Lumina.Media.Org.storage_limit_bytes()

        if current + file_size > limit do
          Ash.Changeset.add_error(changeset, field: :file_size, message: @storage_limit_message)
        else
          changeset
        end
      end
    end)
  end
end
