defmodule Lumina.Accounts.OrgInvite do
  @moduledoc """
  Invite links and codes for joining organizations.
  Created by admins or org owners; redeemed by authenticated users.
  """

  use Ash.Resource,
    otp_app: :lumina,
    domain: Lumina.Accounts,
    data_layer: AshSqlite.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  sqlite do
    table "org_invites"
    repo Lumina.Repo
  end

  code_interface do
    define :create, args: [:org_id, :role, :expires_at]
    define :by_token, args: [:token]
    define :redeem, args: [:token]
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:org_id, :role, :expires_at, :max_uses]

      change fn changeset, _context ->
        token = :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
        Ash.Changeset.force_change_attribute(changeset, :token, token)
      end

      change fn changeset, _context ->
        Ash.Changeset.force_change_attribute(changeset, :use_count, 0)
      end
    end

    read :by_token do
      argument :token, :string, allow_nil?: false
      get? true
      filter expr(token == ^arg(:token))
    end

    update :increment_use do
      require_atomic? false

      change fn changeset, _context ->
        current = Ash.Changeset.get_attribute(changeset, :use_count) || 0
        Ash.Changeset.force_change_attribute(changeset, :use_count, current + 1)
      end
    end

    action :redeem, :struct do
      argument :token, :string, allow_nil?: false

      run fn input, _opts ->
        token = input.arguments.token
        actor = input.context.actor

        if is_nil(actor) do
          {:error, Ash.Error.Changeset.forbidden("You must be signed in to join an organization")}
        else
          case Lumina.Accounts.OrgInvite
               |> Ash.Query.for_read(:read)
               |> Ash.Query.filter(token: token)
               |> Ash.read(authorize?: false) do
            {:ok, [invite | _]} ->
              cond do
                DateTime.compare(invite.expires_at, DateTime.utc_now()) == :lt ->
                  {:error, Ash.Error.Changeset.forbidden("This invite has expired")}

                invite.max_uses != nil and invite.use_count >= invite.max_uses ->
                  {:error,
                   Ash.Error.Changeset.forbidden("This invite has reached its maximum uses")}

                true ->
                  # Check if already a member
                  case Lumina.Accounts.OrgMembership
                       |> Ash.Query.for_read(:read)
                       |> Ash.Query.filter(user_id: actor.id, org_id: invite.org_id)
                       |> Ash.read(authorize?: false) do
                    {:ok, [_ | _]} ->
                      # Already a member - load org and return success
                      org = Lumina.Media.Org |> Ash.get!(invite.org_id, authorize?: false)
                      {:ok, %{org: org, already_member: true}}

                    {:ok, []} ->
                      # Create membership
                      {:ok, _membership} =
                        Lumina.Accounts.OrgMembership
                        |> Ash.Changeset.for_create(:create, %{
                          user_id: actor.id,
                          org_id: invite.org_id,
                          role: invite.role
                        })
                        |> Ash.create(authorize?: false)

                      # Increment use_count
                      invite
                      |> Ash.Changeset.for_update(:increment_use, %{})
                      |> Ash.update(authorize?: false)

                      org = Lumina.Media.Org |> Ash.get!(invite.org_id, authorize?: false)
                      {:ok, %{org: org, already_member: false}}
                  end
              end

            {:ok, []} ->
              {:error, Ash.Error.Changeset.forbidden("Invalid or expired invite")}

            {:error, _} ->
              {:error, Ash.Error.Changeset.forbidden("Invalid or expired invite")}
          end
        end
      end
    end
  end

  policies do
    policy action_type(:create) do
      authorize_if Ash.Policy.Check.Builtins.actor_attribute_equals(:role, :admin)
      authorize_if expr(exists(org.memberships, user_id == ^actor(:id) and role == :owner))
    end

    policy action_type(:read) do
      authorize_if Ash.Policy.Check.Builtins.actor_attribute_equals(:role, :admin)
      authorize_if expr(exists(org.memberships, user_id == ^actor(:id) and role == :owner))
    end

    policy action_type(:destroy) do
      authorize_if Ash.Policy.Check.Builtins.actor_attribute_equals(:role, :admin)
      authorize_if expr(exists(org.memberships, user_id == ^actor(:id) and role == :owner))
    end

    policy action(:redeem) do
      authorize_if actor_present()
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :token, :string do
      allow_nil? false
      public? true
    end

    attribute :role, :atom do
      allow_nil? false
      constraints one_of: [:owner, :member]
      public? true
    end

    attribute :expires_at, :utc_datetime do
      allow_nil? false
      public? true
    end

    attribute :max_uses, :integer do
      public? true
    end

    attribute :use_count, :integer do
      allow_nil? false
      default 0
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
  end

  identities do
    identity :unique_token, [:token]
  end
end
