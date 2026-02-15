defmodule Lumina.Media.Org do
  @moduledoc """
  Organization resource. Each org has a 4GB storage limit for photo uploads.
  """
  use Ash.Resource,
    otp_app: :lumina,
    domain: Lumina.Media,
    data_layer: AshSqlite.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  @storage_limit_bytes 4 * 1024 * 1024 * 1024

  def storage_limit_bytes, do: @storage_limit_bytes

  sqlite do
    table "orgs"
    repo Lumina.Repo
  end

  code_interface do
    define :create, args: [:name, :slug]
    define :by_slug, args: [:slug]
    define :for_user, args: [:user_id]
  end

  actions do
    defaults [:read, :destroy]

    update :update do
      accept [:name, :slug]
    end

    create :create do
      accept [:name, :slug]

      change Lumina.Media.Org.GenerateSlugFromName
    end

    read :by_slug do
      argument :slug, :string, allow_nil?: false
      get? true
      filter expr(slug == ^arg(:slug))
    end

    read :for_user do
      argument :user_id, :uuid, allow_nil?: false
      filter expr(exists(memberships, user_id == ^arg(:user_id)))
    end
  end

  policies do
    policy action_type(:create) do
      authorize_if Ash.Policy.Check.Builtins.actor_attribute_equals(:role, :admin)
    end

    policy action_type(:read) do
      authorize_if expr(exists(memberships, user_id == ^actor(:id)))
      authorize_if Ash.Policy.Check.Builtins.actor_attribute_equals(:role, :admin)
    end

    policy action_type([:update, :destroy]) do
      authorize_if expr(exists(memberships, user_id == ^actor(:id) and role == :owner))
      authorize_if Ash.Policy.Check.Builtins.actor_attribute_equals(:role, :admin)
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
      public? true
    end

    attribute :slug, :string do
      allow_nil? false
      public? true
    end

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    has_many :memberships, Lumina.Accounts.OrgMembership do
      destination_attribute :org_id
      public? true
    end

    has_many :albums, Lumina.Media.Album do
      destination_attribute :org_id
      public? true
    end

    has_many :photos, Lumina.Media.Photo do
      destination_attribute :org_id
      public? true
    end

    has_many :share_links, Lumina.Media.ShareLink do
      destination_attribute :org_id
      public? true
    end

    many_to_many :users, Lumina.Accounts.User do
      through Lumina.Accounts.OrgMembership
      source_attribute_on_join_resource :org_id
      destination_attribute_on_join_resource :user_id
      public? true
    end
  end

  identities do
    identity :unique_slug, [:slug]
  end
end
