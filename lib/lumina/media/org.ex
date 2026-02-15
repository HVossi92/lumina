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
    defaults [:read]

    destroy :destroy do
      primary? true
      require_atomic? false

      # Manually destroy multitenant resources (photos, albums, share_links)
      # with the org's id as tenant, since cascade_destroy doesn't handle multitenancy
      change before_action(fn changeset, context ->
               org = changeset.data
               actor = context.actor

               # Delete photos (with tenant, also deletes files via Photo's before_action)
               photos =
                 Ash.read!(Lumina.Media.Photo, actor: actor, tenant: org.id, authorize?: false)

               Enum.each(photos, fn photo ->
                 Ash.destroy!(photo, actor: actor, tenant: org.id, authorize?: false)
               end)

               # Delete share_links (global? true, but still has org_id tenant)
               share_links =
                 Ash.read!(Lumina.Media.ShareLink,
                   actor: actor,
                   tenant: org.id,
                   authorize?: false
                 )

               Enum.each(share_links, fn share_link ->
                 Ash.destroy!(share_link, actor: actor, tenant: org.id, authorize?: false)
               end)

               # Delete albums (with tenant)
               albums =
                 Ash.read!(Lumina.Media.Album, actor: actor, tenant: org.id, authorize?: false)

               Enum.each(albums, fn album ->
                 Ash.destroy!(album, actor: actor, tenant: org.id, authorize?: false)
               end)

               changeset
             end)

      # Cascade destroy non-multitenant resources
      change Ash.Resource.Change.Builtins.cascade_destroy(:memberships, after_action?: false)
      change Ash.Resource.Change.Builtins.cascade_destroy(:invites, after_action?: false)
    end

    update :update do
      accept [:name, :slug]
    end

    create :create do
      accept [:name, :slug]

      change Lumina.Media.Org.GenerateSlugFromName
      change Lumina.Media.Org.AddCreatorAsOwner
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

    has_many :invites, Lumina.Accounts.OrgInvite do
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
