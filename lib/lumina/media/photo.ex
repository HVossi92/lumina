defmodule Lumina.Media.Photo do
  use Ash.Resource,
    otp_app: :lumina,
    domain: Lumina.Media,
    data_layer: AshSqlite.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  sqlite do
    table "photos"
    repo Lumina.Repo
  end

  code_interface do
    define :create
    define :for_album, args: [:album_id]
    define :add_tags
    define :rename
  end

  actions do
    defaults [:read, :update]

    destroy :destroy do
      primary? true
      require_atomic? false

      change before_action(fn changeset, _context ->
               photo = changeset.data

               if photo do
                 _ = File.rm(photo.original_path)
                 _ = File.rm(photo.thumbnail_path)
               end

               changeset
             end)
    end

    update :rename do
      accept [:filename]

      validate present(:filename)
    end

    create :create do
      accept [
        :filename,
        :original_path,
        :thumbnail_path,
        :file_size,
        :content_type,
        :tags,
        :album_id,
        :uploaded_by_id
      ]

      change Lumina.Media.Photo.Changes.ValidateStorageLimit

      change fn changeset, _context ->
        case Ash.Changeset.get_attribute(changeset, :album_id) do
          nil ->
            changeset

          album_id ->
            # Use Repo.get! to bypass Ash multitenancy (Album requires a tenant,
            # but we're deriving the org_id from the album in an internal context)
            album = Lumina.Repo.get!(Lumina.Media.Album, album_id)
            Ash.Changeset.force_change_attribute(changeset, :org_id, album.org_id)
        end
      end
    end

    read :for_album do
      argument :album_id, :uuid, allow_nil?: false
      filter expr(album_id == ^arg(:album_id))
    end

    update :add_tags do
      accept [:tags]
    end
  end

  policies do
    policy action_type(:read) do
      authorize_if expr(exists(org.memberships, user_id == ^actor(:id)))
    end

    policy action_type(:create) do
      # For create actions, filter expressions referencing relationships can't be used.
      # Authorization is enforced at the LiveView/domain layer (only org members
      # can access the photo upload form).
      authorize_if actor_present()
    end

    policy action_type([:update, :destroy]) do
      authorize_if expr(exists(org.memberships, user_id == ^actor(:id)))
    end
  end

  multitenancy do
    strategy :attribute
    attribute :org_id
  end

  attributes do
    uuid_primary_key :id

    attribute :filename, :string do
      allow_nil? false
      public? true
    end

    attribute :original_path, :string do
      allow_nil? false
      public? true
    end

    attribute :thumbnail_path, :string do
      allow_nil? false
      public? true
    end

    attribute :file_size, :integer do
      public? true
    end

    attribute :content_type, :string do
      public? true
    end

    attribute :tags, {:array, :string} do
      default []
      public? true
    end

    attribute :org_id, :uuid do
      allow_nil? false
      public? true
    end

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :album, Lumina.Media.Album do
      allow_nil? false
      attribute_writable? true
      public? true
    end

    belongs_to :org, Lumina.Media.Org do
      allow_nil? false
      attribute_writable? true
      public? true
    end

    belongs_to :uploaded_by, Lumina.Accounts.User do
      attribute_writable? true
      public? true
    end
  end
end
