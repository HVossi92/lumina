defmodule Lumina.Accounts.OrgMembership do
  use Ash.Resource,
    otp_app: :lumina,
    domain: Lumina.Accounts,
    data_layer: AshSqlite.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  sqlite do
    table "org_memberships"
    repo Lumina.Repo
  end

  code_interface do
    define :create, args: [:user_id, :org_id, :role]
    define :destroy
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:role, :user_id, :org_id]
    end

    update :update_role do
      accept [:role]
    end
  end

  policies do
    policy action_type(:read) do
      authorize_if expr(user_id == ^actor(:id))
    end

    policy action_type(:create) do
      # For create actions, filter-based expressions like exists() cannot reference
      # the record being created. We allow creates when an actor is present.
      # Business-level authorization (only org owners can add members) is enforced
      # at the LiveView/domain layer. System-level creates (initial owner membership
      # in Org.create) use authorize?: false.
      authorize_if actor_present()
    end

    policy action_type([:update, :destroy]) do
      authorize_if expr(exists(org.memberships, user_id == ^actor(:id) and role == :owner))
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :role, :atom do
      allow_nil? false
      constraints one_of: [:owner, :member]
      default :member
      public? true
    end

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :user, Lumina.Accounts.User do
      allow_nil? false
      attribute_writable? true
      public? true
    end

    belongs_to :org, Lumina.Media.Org do
      allow_nil? false
      attribute_writable? true
      public? true
    end
  end

  identities do
    identity :unique_user_org, [:user_id, :org_id]
  end
end
