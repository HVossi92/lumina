defmodule Lumina.Media.ShareLink do
  use Ash.Resource,
    otp_app: :lumina,
    domain: Lumina.Media,
    data_layer: AshSqlite.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  import Ecto.Query

  sqlite do
    table "share_links"
    repo Lumina.Repo
  end

  code_interface do
    define :create
    define :by_token, args: [:token]
    define :increment_view_count
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:expires_at, :max_views, :photo_ids, :password_hash, :album_id, :created_by_id]

      change fn changeset, _context ->
        token = :crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)
        Ash.Changeset.force_change_attribute(changeset, :token, token)
      end

      change fn changeset, _context ->
        cond do
          album_id = Ash.Changeset.get_attribute(changeset, :album_id) ->
            # Use Repo.get! to bypass Ash multitenancy for internal org_id derivation
            album = Lumina.Repo.get!(Lumina.Media.Album, album_id)
            Ash.Changeset.force_change_attribute(changeset, :org_id, album.org_id)

          photo_ids = Ash.Changeset.get_attribute(changeset, :photo_ids) ->
            if length(photo_ids) > 0 do
              # Use Repo.get! to bypass Ash multitenancy for internal org_id derivation
              photo = Lumina.Repo.get!(Lumina.Media.Photo, List.first(photo_ids))
              Ash.Changeset.force_change_attribute(changeset, :org_id, photo.org_id)
            else
              changeset
            end

          true ->
            changeset
        end
      end
    end

    update :increment_view_count do
      require_atomic? false

      change before_action(fn changeset, _context ->
               share_link = changeset.data

               # Use atomic database update to prevent race conditions
               {count, _} =
                 Lumina.Repo.update_all(
                   from(sl in "share_links", where: sl.id == ^share_link.id),
                   inc: [view_count: 1]
                 )

               if count > 0 do
                 # Reload the updated view_count
                 {:ok, updated} = Lumina.Media.ShareLink.by_token(share_link.token)
                 Ash.Changeset.force_change_attribute(changeset, :view_count, updated.view_count)
               else
                 changeset
               end
             end)
    end

    read :by_token do
      argument :token, :string, allow_nil?: false
      get? true
      filter expr(token == ^arg(:token))
    end
  end

  policies do
    policy action_type(:read) do
      authorize_if always()
    end

    policy action_type(:create) do
      # For create actions, filter expressions referencing relationships can't be used.
      # Authorization is enforced at the LiveView/domain layer (only org members
      # can access the share link creation form).
      authorize_if actor_present()
    end

    policy action_type(:destroy) do
      authorize_if expr(exists(org.memberships, user_id == ^actor(:id)))
    end

    policy action(:increment_view_count) do
      authorize_if always()
    end
  end

  multitenancy do
    strategy :attribute
    attribute :org_id
    global? true
  end

  attributes do
    uuid_primary_key :id

    attribute :token, :string do
      allow_nil? false
      public? true
    end

    attribute :password_hash, :string do
      sensitive? true
      public? true
    end

    attribute :expires_at, :utc_datetime do
      allow_nil? false
      public? true
    end

    attribute :view_count, :integer do
      default 0
      public? true
    end

    attribute :max_views, :integer do
      public? true
    end

    attribute :photo_ids, {:array, :uuid} do
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
    belongs_to :org, Lumina.Media.Org do
      allow_nil? false
      attribute_writable? true
      public? true
    end

    belongs_to :album, Lumina.Media.Album do
      attribute_writable? true
      public? true
    end

    belongs_to :created_by, Lumina.Accounts.User do
      attribute_writable? true
      public? true
    end
  end

  identities do
    identity :unique_token, [:token]
  end
end
