defmodule Lumina.Media.Album do
  use Ash.Resource,
    otp_app: :lumina,
    domain: Lumina.Media,
    data_layer: AshSqlite.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  sqlite do
    table "albums"
    repo Lumina.Repo
  end

  code_interface do
    define :create, args: [:name, :org_id]
    define :for_org, args: [:org_id]
  end

  actions do
    defaults [:read, :destroy]

    update :update do
      accept [:name, :description]
    end

    create :create do
      accept [:name, :description, :org_id]
    end

    read :for_org do
      argument :org_id, :uuid, allow_nil?: false
      filter expr(org_id == ^arg(:org_id))
    end
  end

  policies do
    policy action_type(:read) do
      authorize_if expr(exists(org.memberships, user_id == ^actor(:id)))
    end

    policy action_type(:create) do
      # For create actions, filter expressions referencing relationships can't be used.
      # Authorization is enforced at the LiveView/domain layer (only org members
      # can access the album creation form).
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

    attribute :name, :string do
      allow_nil? false
      public? true
    end

    attribute :description, :string do
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

    has_many :photos, Lumina.Media.Photo do
      destination_attribute :album_id
      public? true
    end
  end
end
