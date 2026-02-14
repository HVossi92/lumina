defmodule Lumina.Accounts.User do
  use Ash.Resource,
    otp_app: :lumina,
    domain: Lumina.Accounts,
    data_layer: AshSqlite.DataLayer,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshAuthentication]

  sqlite do
    table "users"
    repo Lumina.Repo
  end

  authentication do
    strategies do
      password :password do
        identity_field :email
        hashed_password_field :hashed_password
        register_action_name :register_with_password
      end

      # Without confirmation add-on we set prevent_hijacking?: false.
      # See https://hexdocs.pm/ash_authentication/AshAuthentication.Strategy.OAuth2.html
      google do
        client_id Lumina.Secrets
        redirect_uri Lumina.Secrets
        client_secret Lumina.Secrets
        prevent_hijacking? false
      end
    end

    add_ons do
      log_out_everywhere do
        apply_on_password_change? true
      end
    end

    tokens do
      enabled? true
      token_resource Lumina.Accounts.Token
      signing_secret Lumina.Secrets
      store_all_tokens? true
      require_token_presence_for_authentication? true
    end
  end

  actions do
    defaults [:read]

    update :update do
      accept [:role]
    end

    create :register_with_google do
      argument :user_info, :map, allow_nil?: false
      argument :oauth_tokens, :map, allow_nil?: false
      upsert? true
      upsert_identity :unique_email
      upsert_fields []

      change AshAuthentication.GenerateTokenChange

      change fn changeset, _ctx ->
        user_info = Ash.Changeset.get_argument(changeset, :user_info)
        Ash.Changeset.change_attributes(changeset, Map.take(user_info, ["email"]))
      end
    end

    read :get_by_subject do
      description "Get a user by the subject claim in a JWT"
      argument :subject, :string, allow_nil?: false
      get? true
      prepare AshAuthentication.Preparations.FilterBySubject
    end
  end

  policies do
    bypass AshAuthentication.Checks.AshAuthenticationInteraction do
      authorize_if always()
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :email, :string do
      allow_nil? false
      public? true
    end

    attribute :role, :atom do
      allow_nil? false
      default :user
      constraints one_of: [:admin, :user]
      public? true
    end

    attribute :hashed_password, :string do
      allow_nil? true
      sensitive? true
    end

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    has_many :org_memberships, Lumina.Accounts.OrgMembership do
      destination_attribute :user_id
      public? true
    end

    many_to_many :orgs, Lumina.Media.Org do
      through Lumina.Accounts.OrgMembership
      source_attribute_on_join_resource :user_id
      destination_attribute_on_join_resource :org_id
      public? true
    end
  end

  identities do
    identity :unique_email, [:email]
  end
end
