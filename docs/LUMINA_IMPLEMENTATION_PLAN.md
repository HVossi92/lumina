# Lumina: Multi-Org Photo Sharing Platform
## Detailed Implementation Plan

---

## Project Overview

**Lumina** is a simplified PhotoPrism alternative focused on multi-organization photo sharing with albums. Built for both private and professional enterprise users.

### Core Use Case
Host one application, use it with different groups of people (family, work, friends) with complete data isolation.

---

## Tech Stack

### Core Framework
- **Elixir 1.17+** / **OTP 27+**
- **Phoenix 1.8.0** with LiveView 1.1
- **Ash 3.4+** (ash, ash_phoenix, ash_sqlite)
- **ash_authentication** + **ash_authentication_phoenix**
- **ash_admin** (auto-generated admin interface)
- **ash_oban** + **oban_web** (background jobs with UI)
- **ash_paper_trail** (audit logging)
- **SQLite** via ecto_sqlite3

### Image Processing
- **vix** (libvips wrapper - fast, memory efficient)

### Development Tools
- **live_debugger** (debugging LiveView)
- **tidewave** (additional dev tooling)
- **ExUnit** (testing framework)
- **ExCoveralls** (test coverage)
- **Credo** (code quality)
- **Dialyzer** (type checking)

### Deployment
- **Docker** (containerization)
- **Caddy** (reverse proxy + HTTPS)
- **Cloudflare** (DNS management)
- **Fedora VPS** (Hetzner hosting)

---

## Project Structure

```
lumina/
├── lib/
│   ├── lumina/                  # Domain logic (Ash resources)
│   │   ├── accounts/            # User, Token, OrgMembership
│   │   │   ├── user.ex
│   │   │   ├── org_membership.ex
│   │   │   └── accounts.ex      # Domain module
│   │   ├── media/               # Org, Album, Photo, ShareLink
│   │   │   ├── org.ex
│   │   │   ├── album.ex
│   │   │   ├── photo.ex
│   │   │   ├── share_link.ex
│   │   │   ├── thumbnail.ex     # Image processing logic
│   │   │   └── media.ex         # Domain module
│   │   └── jobs/                # Oban workers
│   │       └── process_upload.ex
│   ├── lumina_web/              # Phoenix web interface
│   │   ├── live/                # LiveView modules
│   │   │   ├── dashboard_live.ex
│   │   │   ├── org_live/
│   │   │   │   ├── index.ex
│   │   │   │   ├── new.ex
│   │   │   │   └── show.ex
│   │   │   ├── album_live/
│   │   │   │   ├── new.ex
│   │   │   │   ├── show.ex
│   │   │   │   └── share.ex
│   │   │   ├── photo_live/
│   │   │   │   └── upload.ex
│   │   │   ├── share_live/
│   │   │   │   └── show.ex
│   │   │   └── admin_live/
│   │   │       └── backup.ex
│   │   ├── components/          # Reusable components
│   │   │   └── core_components.ex
│   │   ├── controllers/         # HTTP controllers
│   │   │   └── admin_controller.ex
│   │   └── live_user_auth.ex    # Auth helpers
│   └── lumina.ex
├── priv/
│   ├── repo/
│   │   └── migrations/
│   ├── static/
│   │   └── uploads/
│   │       ├── originals/       # Full-size photos
│   │       └── thumbnails/      # Generated thumbnails
│   └── resource_snapshots/      # Ash snapshots
├── test/
│   ├── lumina/
│   │   ├── accounts/
│   │   ├── media/
│   │   └── jobs/
│   ├── lumina_web/
│   │   ├── live/
│   │   └── integration/
│   ├── support/
│   └── test_helper.exs
├── config/
│   ├── config.exs
│   ├── dev.exs
│   ├── test.exs
│   ├── runtime.exs
│   └── prod.exs
├── assets/
├── .formatter.exs
├── .gitignore
├── mix.exs
├── Dockerfile
├── docker-compose.yml
├── Caddyfile
└── README.md
```

---

## Database Schema

### Accounts Domain

#### **User**
```elixir
- id (uuid, primary key)
- email (string, unique, required)
- hashed_password (string)
- confirmed_at (timestamp)
- inserted_at (timestamp)
- updated_at (timestamp)
```

**Relationships:**
- `has_many :org_memberships`
- `many_to_many :orgs` (through OrgMembership)

**Identities:**
- `unique_email` on `[:email]`

---

#### **OrgMembership**
```elixir
- id (uuid, primary key)
- user_id (uuid, foreign key → users)
- org_id (uuid, foreign key → orgs)
- role (enum: :owner, :member)
- inserted_at (timestamp)
- updated_at (timestamp)
```

**Relationships:**
- `belongs_to :user`
- `belongs_to :org`

**Constraints:**
- Unique index: `[user_id, org_id]`

**Policies:**
- Users can read their own memberships
- Only org owners can create/delete memberships

---

### Media Domain

#### **Org**
```elixir
- id (uuid, primary key)
- name (string, required)
- slug (string, unique, required)
- inserted_at (timestamp)
- updated_at (timestamp)
```

**Relationships:**
- `has_many :memberships`
- `has_many :albums`
- `has_many :photos`
- `has_many :share_links`
- `many_to_many :users` (through OrgMembership)

**Identities:**
- `unique_slug` on `[:slug]`

**Policies:**
- Anyone can create an org (becomes owner)
- Only members can read org
- Only owners can update/delete org

---

#### **Album**
```elixir
- id (uuid, primary key)
- org_id (uuid, foreign key → orgs) [multi-tenancy attribute]
- name (string, required)
- description (text, nullable)
- cover_photo_id (uuid, nullable)
- inserted_at (timestamp)
- updated_at (timestamp)
```

**Relationships:**
- `belongs_to :org`
- `has_many :photos`

**Multi-tenancy:**
- Strategy: `attribute`
- Attribute: `:org_id`

**Policies:**
- Org members can read albums
- Org members can create/update/delete albums

---

#### **Photo**
```elixir
- id (uuid, primary key)
- album_id (uuid, foreign key → albums)
- org_id (uuid, foreign key → orgs) [multi-tenancy attribute]
- filename (string, required)
- original_path (string, required)
- thumbnail_path (string, required)
- file_size (integer, bytes)
- content_type (string, e.g., "image/jpeg")
- tags ({array, :string}, default: [])
- uploaded_by_id (uuid, foreign key → users)
- inserted_at (timestamp)
- updated_at (timestamp)
```

**Relationships:**
- `belongs_to :album`
- `belongs_to :org`
- `belongs_to :uploaded_by` (User)

**Multi-tenancy:**
- Strategy: `attribute`
- Attribute: `:org_id`

**Policies:**
- Org members can read photos
- Org members can create/update/delete photos

---

#### **ShareLink**
```elixir
- id (uuid, primary key)
- token (string, unique, required)
- org_id (uuid, foreign key → orgs) [multi-tenancy attribute]
- album_id (uuid, foreign key → albums, nullable)
- photo_ids ({array, :uuid}, default: [])
- password_hash (string, nullable)
- expires_at (utc_datetime, required)
- view_count (integer, default: 0)
- max_views (integer, nullable)
- created_by_id (uuid, foreign key → users)
- inserted_at (timestamp)
- updated_at (timestamp)
```

**Relationships:**
- `belongs_to :org`
- `belongs_to :album` (nullable - if null, uses photo_ids)
- `belongs_to :created_by` (User)

**Multi-tenancy:**
- Strategy: `attribute`
- Attribute: `:org_id`

**Policies:**
- Public read access (by token)
- Only org members can create/delete links

**Notes:**
- If `album_id` is set, shares entire album
- If `album_id` is null, uses `photo_ids` array to share specific photos

---

## Feature Specifications

### 1. User Management
- ✅ Email/password registration
- ✅ Email/password login
- ✅ Session management
- ✅ Password hashing (bcrypt)
- ⏭️ Email confirmation (future)
- ⏭️ Password reset (future)

### 2. Organization Management
- ✅ Create organization (user becomes owner)
- ✅ View user's organizations
- ✅ Update organization details (owner only)
- ✅ Delete organization (owner only)
- ✅ Invite users to organization (owner only)
- ✅ Remove users from organization (owner only)
- ✅ Organization member listing

**Permission Model:**
- **Owner**: Full control over org, albums, photos, share links, memberships
- **Member**: Can view/upload/edit/delete all photos in the org

### 3. Album Management
- ✅ Create album in organization
- ✅ View albums (filtered by org)
- ✅ Update album details
- ✅ Delete album (cascade deletes photos)
- ✅ Set album cover photo
- ✅ Album description (plain text)

### 4. Photo Management
- ✅ Upload photos (multi-file)
- ✅ Automatic thumbnail generation (background job)
- ✅ View photos in grid layout
- ✅ Delete photos (removes files from disk)
- ✅ Add/edit/remove tags
- ✅ Filter photos by tags
- ⏭️ EXIF metadata extraction (future)
- ⏭️ Face detection (future)

**Supported Formats:**
- JPEG (.jpg, .jpeg)
- PNG (.png)
- GIF (.gif)
- WebP (.webp)

**Constraints:**
- Max file size: 10MB per photo
- Max uploads: 10 photos per batch

### 5. Share Links
- ✅ Generate shareable link for album
- ✅ Generate shareable link for specific photos
- ✅ Set expiration date
- ✅ Optional password protection
- ✅ View count tracking
- ✅ Optional max view limit
- ✅ Public access (no auth required)
- ✅ Token-based access

### 6. Admin Features
- ✅ Password-protected backup page
- ✅ Download complete backup (.tar.gz)
- ✅ Includes SQLite database + all photos
- ⏭️ Ash Admin interface (auto-generated)

### 7. Multi-Tenancy
- ✅ Attribute-based strategy (org_id)
- ✅ Automatic query filtering by org
- ✅ Complete data isolation between orgs
- ✅ Users can belong to multiple orgs

---

## Step-by-Step Implementation Plan

### Phase 1: Project Setup (Days 1-2)

#### Step 1.1: Initialize Project with Igniter ✅
```bash
mix archive.install hex igniter_new --force
mix archive.install hex phx_new 1.8.3 --force

mix igniter.new lumina --with phx.new --with-args "--database sqlite3" \
  --install ash,ash_phoenix --install ash_sqlite,ash_authentication \
  --install ash_authentication_phoenix,ash_admin \
  --install ash_oban,oban_web --install live_debugger,tidewave \
  --install ash_paper_trail --setup --yes
```

**Verify:**
- ✅ Project structure created
- ✅ Dependencies installed
- ✅ Database created
- ✅ Server starts successfully

---

#### Step 1.2: Add Additional Dependencies

**Edit mix.exs:**
```elixir
defp deps do
  [
    # ... existing deps from igniter ...
    
    # Image Processing
    {:vix, "~> 0.26"},
    
    # Testing
    {:excoveralls, "~> 0.18", only: :test},
    {:wallaby, "~> 0.30", only: :test, runtime: false},
  ]
end
```

**Install:**
```bash
mix deps.get
```

**Tests:**
- ✅ All dependencies compile
- ✅ Server starts without errors

---

#### Step 1.3: Configure Ash Domains

**config/config.exs:**
```elixir
config :lumina,
  ash_domains: [Lumina.Accounts, Lumina.Media]

config :ash, :disable_async?, true # For SQLite
```

**Create upload directories:**
```bash
mkdir -p priv/static/uploads/originals
mkdir -p priv/static/uploads/thumbnails
```

---

### Phase 2: Accounts Domain (Days 3-5)

#### Step 2.1: Create User Resource

**lib/lumina/accounts/user.ex:**
```elixir
defmodule Lumina.Accounts.User do
  use Ash.Resource,
    domain: Lumina.Accounts,
    data_layer: AshSqlite.DataLayer,
    extensions: [AshAuthentication],
    authorizers: [Ash.Policy.Authorizer]

  sqlite do
    table "users"
    repo Lumina.Repo
  end

  attributes do
    uuid_primary_key :id
    
    attribute :email, :string do
      allow_nil? false
      public? true
    end
    
    attribute :hashed_password, :string do
      allow_nil? false
      sensitive? true
    end
    
    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  authentication do
    strategies do
      password :password do
        identity_field :email
        
        resettable do
          sender Lumina.Accounts.User.Senders.SendPasswordResetEmail
        end
      end
    end
    
    tokens do
      enabled? true
      token_resource Lumina.Accounts.Token
      signing_secret &get_config/2
    end
  end

  identities do
    identity :unique_email, [:email]
  end

  relationships do
    has_many :org_memberships, Lumina.Accounts.OrgMembership do
      destination_attribute :user_id
    end
    
    many_to_many :orgs, Lumina.Media.Org do
      through Lumina.Accounts.OrgMembership
      source_attribute_on_join_resource :user_id
      destination_attribute_on_join_resource :org_id
    end
  end

  policies do
    policy action_type(:read) do
      authorize_if expr(id == ^actor(:id))
    end
    
    policy action_type([:create, :update, :destroy]) do
      authorize_if expr(id == ^actor(:id))
    end
  end

  actions do
    defaults [:read, :destroy]
    
    read :get_by_email do
      argument :email, :string, allow_nil?: false
      get? true
      filter expr(email == ^arg(:email))
    end
  end

  code_interface do
    define :get_by_email, args: [:email]
  end

  defp get_config(path, _resource) do
    Application.fetch_env!(:lumina, path)
  end
end
```

**Create Token resource (for ash_authentication):**

**lib/lumina/accounts/token.ex:**
```elixir
defmodule Lumina.Accounts.Token do
  use Ash.Resource,
    domain: Lumina.Accounts,
    data_layer: AshSqlite.DataLayer,
    extensions: [AshAuthentication.TokenResource],
    authorizers: [Ash.Policy.Authorizer]

  sqlite do
    table "tokens"
    repo Lumina.Repo
  end

  policies do
    bypass AshAuthentication.Checks.AshAuthenticationInteraction do
      authorize_if always()
    end
  end
end
```

**Tests to write:**
- ✅ `test/lumina/accounts/user_test.exs`
  - User registration with valid email/password
  - Registration fails with duplicate email
  - Registration fails with weak password
  - User login with correct credentials
  - Login fails with wrong password
  - Password hashing works correctly
  - Get user by email

---

#### Step 2.2: Create OrgMembership Resource

**lib/lumina/accounts/org_membership.ex:**
```elixir
defmodule Lumina.Accounts.OrgMembership do
  use Ash.Resource,
    domain: Lumina.Accounts,
    data_layer: AshSqlite.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  sqlite do
    table "org_memberships"
    repo Lumina.Repo
  end

  attributes do
    uuid_primary_key :id
    
    attribute :role, :atom do
      allow_nil? false
      constraints one_of: [:owner, :member]
      default :member
    end
    
    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :user, Lumina.Accounts.User do
      allow_nil? false
      attribute_writable? true
    end
    
    belongs_to :org, Lumina.Media.Org do
      allow_nil? false
      attribute_writable? true
    end
  end

  identities do
    identity :unique_user_org, [:user_id, :org_id]
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
    # Users can read their own memberships
    policy action_type(:read) do
      authorize_if expr(user_id == ^actor(:id))
    end
    
    # Only org owners can manage memberships
    policy action_type([:create, :update, :destroy]) do
      authorize_if expr(
        org.memberships.user_id == ^actor(:id) and
        org.memberships.role == :owner
      )
    end
  end

  code_interface do
    define :create, args: [:user_id, :org_id, :role]
    define :destroy
  end
end
```

**Tests to write:**
- ✅ `test/lumina/accounts/org_membership_test.exs`
  - Create membership with valid user/org
  - Prevent duplicate memberships (unique constraint)
  - Only org owners can add members
  - Only org owners can remove members
  - Users can read their own memberships
  - Update membership role

---

#### Step 2.3: Create Accounts Domain

**lib/lumina/accounts.ex:**
```elixir
defmodule Lumina.Accounts do
  use Ash.Domain

  resources do
    resource Lumina.Accounts.User do
      define :get_by_email, args: [:email]
    end
    
    resource Lumina.Accounts.Token
    resource Lumina.Accounts.OrgMembership
  end
end
```

**Run migrations:**
```bash
mix ash.codegen accounts
mix ecto.migrate
```

---

### Phase 3: Media Domain (Days 6-10)

#### Step 3.1: Create Org Resource

**lib/lumina/media/org.ex:**
```elixir
defmodule Lumina.Media.Org do
  use Ash.Resource,
    domain: Lumina.Media,
    data_layer: AshSqlite.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  sqlite do
    table "orgs"
    repo Lumina.Repo
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
    end
    
    has_many :albums, Lumina.Media.Album do
      destination_attribute :org_id
    end
    
    has_many :photos, Lumina.Media.Photo do
      destination_attribute :org_id
    end
    
    has_many :share_links, Lumina.Media.ShareLink do
      destination_attribute :org_id
    end
    
    many_to_many :users, Lumina.Accounts.User do
      through Lumina.Accounts.OrgMembership
      source_attribute_on_join_resource :org_id
      destination_attribute_on_join_resource :user_id
    end
  end

  identities do
    identity :unique_slug, [:slug]
  end

  actions do
    defaults [:read, :update, :destroy]
    
    create :create do
      accept [:name, :slug]
      argument :owner_id, :uuid, allow_nil?: false
      
      change after_action(fn _changeset, org, context ->
        # Create owner membership
        Lumina.Accounts.OrgMembership.create!(
          user_id: context.arguments.owner_id,
          org_id: org.id,
          role: :owner
        )
        
        {:ok, org}
      end)
    end
    
    read :by_slug do
      argument :slug, :string, allow_nil?: false
      get? true
      filter expr(slug == ^arg(:slug))
    end
    
    read :for_user do
      argument :user_id, :uuid, allow_nil?: false
      filter expr(memberships.user_id == ^arg(:user_id))
    end
  end

  policies do
    # Anyone can create an org
    policy action_type(:create) do
      authorize_if always()
    end
    
    # Only members can read org
    policy action_type(:read) do
      authorize_if expr(memberships.user_id == ^actor(:id))
    end
    
    # Only owners can update/delete org
    policy action_type([:update, :destroy]) do
      authorize_if expr(
        memberships.user_id == ^actor(:id) and
        memberships.role == :owner
      )
    end
  end

  code_interface do
    define :create, args: [:name, :slug, :owner_id]
    define :by_slug, args: [:slug]
    define :for_user, args: [:user_id]
  end
end
```

**Tests to write:**
- ✅ `test/lumina/media/org_test.exs`
  - Create org and auto-assign owner
  - Org slug must be unique
  - Only members can view org
  - Only owners can update org
  - Only owners can delete org
  - List user's orgs
  - Get org by slug

---

#### Step 3.2: Create Album Resource

**lib/lumina/media/album.ex:**
```elixir
defmodule Lumina.Media.Album do
  use Ash.Resource,
    domain: Lumina.Media,
    data_layer: AshSqlite.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  sqlite do
    table "albums"
    repo Lumina.Repo
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
    end
    
    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :org, Lumina.Media.Org do
      allow_nil? false
      attribute_writable? true
    end
    
    has_many :photos, Lumina.Media.Photo do
      destination_attribute :album_id
    end
  end

  multitenancy do
    strategy :attribute
    attribute :org_id
    parse_attribute {Lumina.Media.Album, :get_org_id, []}
  end

  actions do
    defaults [:read, :update, :destroy]
    
    create :create do
      accept [:name, :description, :org_id]
    end
    
    read :for_org do
      argument :org_id, :uuid, allow_nil?: false
      filter expr(org_id == ^arg(:org_id))
    end
  end

  policies do
    # Org members can read albums
    policy action_type(:read) do
      authorize_if expr(org.memberships.user_id == ^actor(:id))
    end
    
    # Org members can create/update/delete albums
    policy action_type([:create, :update, :destroy]) do
      authorize_if expr(org.memberships.user_id == ^actor(:id))
    end
  end

  code_interface do
    define :create, args: [:name, :org_id]
    define :for_org, args: [:org_id]
  end

  def get_org_id(%{tenant: org_id}), do: org_id
  def get_org_id(_), do: nil
end
```

**Tests to write:**
- ✅ `test/lumina/media/album_test.exs`
  - Create album in org
  - List albums filtered by org
  - Only org members can view albums
  - Org members can create albums
  - Org members can edit albums
  - Org members can delete albums
  - Multi-tenancy filtering works

---

#### Step 3.3: Create Photo Resource

**lib/lumina/media/photo.ex:**
```elixir
defmodule Lumina.Media.Photo do
  use Ash.Resource,
    domain: Lumina.Media,
    data_layer: AshSqlite.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  sqlite do
    table "photos"
    repo Lumina.Repo
  end

  attributes do
    uuid_primary_key :id
    
    attribute :filename, :string do
      allow_nil? false
      public? true
    end
    
    attribute :original_path, :string do
      allow_nil? false
    end
    
    attribute :thumbnail_path, :string do
      allow_nil? false
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
    end
    
    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :album, Lumina.Media.Album do
      allow_nil? false
      attribute_writable? true
    end
    
    belongs_to :org, Lumina.Media.Org do
      allow_nil? false
      attribute_writable? true
    end
    
    belongs_to :uploaded_by, Lumina.Accounts.User do
      attribute_writable? true
    end
  end

  multitenancy do
    strategy :attribute
    attribute :org_id
    parse_attribute {Lumina.Media.Photo, :get_org_id, []}
  end

  actions do
    defaults [:read, :update, :destroy]
    
    create :create do
      accept [:filename, :original_path, :thumbnail_path, :file_size, :content_type, :tags, :album_id, :uploaded_by_id]
      
      change fn changeset, _context ->
        # Auto-set org_id from album
        case Ash.Changeset.get_attribute(changeset, :album_id) do
          nil -> 
            changeset
          album_id ->
            album = Ash.get!(Lumina.Media.Album, album_id)
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
    # Org members can read photos
    policy action_type(:read) do
      authorize_if expr(org.memberships.user_id == ^actor(:id))
    end
    
    # Org members can create/update/delete photos
    policy action_type([:create, :update, :destroy]) do
      authorize_if expr(org.memberships.user_id == ^actor(:id))
    end
  end

  code_interface do
    define :create
    define :for_album, args: [:album_id]
    define :add_tags
  end

  def get_org_id(%{tenant: org_id}), do: org_id
  def get_org_id(_), do: nil
end
```

**Tests to write:**
- ✅ `test/lumina/media/photo_test.exs`
  - Upload photo to album
  - Photo inherits org_id from album
  - List photos filtered by album
  - Add tags to photo
  - Remove tags from photo
  - Only org members can view photos
  - Only org members can edit photos
  - Delete photo

---

#### Step 3.4: Create ShareLink Resource

**lib/lumina/media/share_link.ex:**
```elixir
defmodule Lumina.Media.ShareLink do
  use Ash.Resource,
    domain: Lumina.Media,
    data_layer: AshSqlite.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  sqlite do
    table "share_links"
    repo Lumina.Repo
  end

  attributes do
    uuid_primary_key :id
    
    attribute :token, :string do
      allow_nil? false
      public? true
    end
    
    attribute :password_hash, :string do
      sensitive? true
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
    end
    
    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :org, Lumina.Media.Org do
      allow_nil? false
      attribute_writable? true
    end
    
    belongs_to :album, Lumina.Media.Album do
      attribute_writable? true
    end
    
    belongs_to :created_by, Lumina.Accounts.User do
      attribute_writable? true
    end
  end

  multitenancy do
    strategy :attribute
    attribute :org_id
    parse_attribute {Lumina.Media.ShareLink, :get_org_id, []}
  end

  actions do
    defaults [:read, :destroy]
    
    create :create do
      accept [:expires_at, :max_views, :photo_ids, :password_hash, :album_id, :created_by_id]
      
      # Generate unique token
      change fn changeset, _context ->
        token = :crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)
        Ash.Changeset.force_change_attribute(changeset, :token, token)
      end
      
      # Set org_id from album or first photo
      change fn changeset, _context ->
        cond do
          album_id = Ash.Changeset.get_attribute(changeset, :album_id) ->
            album = Ash.get!(Lumina.Media.Album, album_id)
            Ash.Changeset.force_change_attribute(changeset, :org_id, album.org_id)
          
          photo_ids = Ash.Changeset.get_attribute(changeset, :photo_ids) ->
            photo = Ash.get!(Lumina.Media.Photo, List.first(photo_ids))
            Ash.Changeset.force_change_attribute(changeset, :org_id, photo.org_id)
          
          true -> 
            changeset
        end
      end
    end
    
    update :increment_view_count do
      change fn changeset, _context ->
        current = Ash.Changeset.get_attribute(changeset, :view_count) || 0
        Ash.Changeset.force_change_attribute(changeset, :view_count, current + 1)
      end
    end
    
    read :by_token do
      argument :token, :string, allow_nil?: false
      get? true
      filter expr(token == ^arg(:token))
    end
  end

  policies do
    # Public read access by token
    policy action_type(:read) do
      authorize_if always()
    end
    
    # Only org members can create/delete links
    policy action_type([:create, :destroy]) do
      authorize_if expr(org.memberships.user_id == ^actor(:id))
    end
    
    # Allow incrementing view count
    policy action(:increment_view_count) do
      authorize_if always()
    end
  end

  code_interface do
    define :create
    define :by_token, args: [:token]
    define :increment_view_count
  end

  def get_org_id(%{tenant: org_id}), do: org_id
  def get_org_id(_), do: nil
end
```

**Tests to write:**
- ✅ `test/lumina/media/share_link_test.exs`
  - Create share link for album
  - Create share link for specific photos
  - Generate unique token
  - Password protection works
  - Expiry date validation
  - View count increments
  - Max views limit enforced
  - Only org members can create links
  - Get share link by token

---

#### Step 3.5: Create Media Domain

**lib/lumina/media.ex:**
```elixir
defmodule Lumina.Media do
  use Ash.Domain

  resources do
    resource Lumina.Media.Org do
      define :create, args: [:name, :slug, :owner_id]
      define :by_slug, args: [:slug]
      define :for_user, args: [:user_id]
    end
    
    resource Lumina.Media.Album do
      define :create, args: [:name, :org_id]
      define :for_org, args: [:org_id]
    end
    
    resource Lumina.Media.Photo do
      define :create
      define :for_album, args: [:album_id]
      define :add_tags
    end
    
    resource Lumina.Media.ShareLink do
      define :create
      define :by_token, args: [:token]
      define :increment_view_count
    end
  end
end
```

**Run migrations:**
```bash
mix ash.codegen media
mix ecto.migrate
```

---

### Phase 4: Image Processing (Days 11-12)

#### Step 4.1: Create Thumbnail Generator

**lib/lumina/media/thumbnail.ex:**
```elixir
defmodule Lumina.Media.Thumbnail do
  @moduledoc """
  Handles thumbnail generation for uploaded photos using libvips.
  """

  @thumbnail_size 400
  @quality 85

  @doc """
  Generate a thumbnail from the source image.
  
  ## Examples
  
      iex> generate("/path/to/original.jpg", "/path/to/thumb.jpg")
      {:ok, "/path/to/thumb.jpg"}
  """
  def generate(source_path, dest_path) do
    with {:ok, image} <- Vix.Vips.Image.new_from_file(source_path),
         {:ok, resized} <- resize_image(image),
         :ok <- write_image(resized, dest_path) do
      {:ok, dest_path}
    else
      {:error, reason} -> 
        {:error, "Thumbnail generation failed: #{inspect(reason)}"}
    end
  end

  defp resize_image(image) do
    {:ok, width} = Vix.Vips.Image.width(image)
    {:ok, height} = Vix.Vips.Image.height(image)
    
    # Calculate scale to fit within thumbnail size
    scale = @thumbnail_size / max(width, height)
    
    # Only resize if image is larger than thumbnail size
    if scale < 1.0 do
      Vix.Vips.Operation.resize(image, scale)
    else
      {:ok, image}
    end
  end

  defp write_image(image, dest_path) do
    # Ensure directory exists
    dest_path
    |> Path.dirname()
    |> File.mkdir_p!()
    
    Vix.Vips.Image.write_to_file(image, dest_path <> "[Q=#{@quality}]")
  end

  @doc """
  Generate thumbnail path for a photo.
  """
  def thumbnail_path(photo_id, filename) do
    ext = Path.extname(filename)
    Path.join(["priv", "static", "uploads", "thumbnails", "#{photo_id}#{ext}"])
  end

  @doc """
  Generate original path for a photo.
  """
  def original_path(photo_id, filename) do
    ext = Path.extname(filename)
    Path.join(["priv", "static", "uploads", "originals", "#{photo_id}#{ext}"])
  end

  @doc """
  Get public URL path for thumbnail.
  """
  def thumbnail_url(photo_id, filename) do
    ext = Path.extname(filename)
    "/uploads/thumbnails/#{photo_id}#{ext}"
  end

  @doc """
  Get public URL path for original.
  """
  def original_url(photo_id, filename) do
    ext = Path.extname(filename)
    "/uploads/originals/#{photo_id}#{ext}"
  end
end
```

**Tests to write:**
- ✅ `test/lumina/media/thumbnail_test.exs`
  - Generate thumbnail from JPEG
  - Generate thumbnail from PNG
  - Generate thumbnail from WebP
  - Handle invalid image file
  - Maintain aspect ratio
  - Don't upscale small images
  - File paths are correct
  - Public URLs are correct

---

#### Step 4.2: Create Upload Worker (Oban)

**lib/lumina/jobs/process_upload.ex:**
```elixir
defmodule Lumina.Jobs.ProcessUpload do
  use Oban.Worker,
    queue: :media,
    max_attempts: 3

  alias Lumina.Media.{Photo, Thumbnail}

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"photo_id" => photo_id}}) do
    photo = Ash.get!(Photo, photo_id)
    
    case Thumbnail.generate(photo.original_path, photo.thumbnail_path) do
      {:ok, _path} -> 
        :ok
      {:error, reason} -> 
        {:error, reason}
    end
  end
end
```

**Configure Oban:**

Add to **config/config.exs:**
```elixir
config :lumina, Oban,
  repo: Lumina.Repo,
  queues: [media: 10],
  plugins: [
    Oban.Plugins.Pruner,
    {Oban.Plugins.Cron, 
      crontab: [
        # Add scheduled jobs here if needed
      ]
    }
  ]
```

**Add Oban to supervision tree in lib/lumina/application.ex:**
```elixir
children = [
  # ... existing children ...
  {Oban, Application.fetch_env!(:lumina, Oban)}
]
```

**Tests to write:**
- ✅ `test/lumina/jobs/process_upload_test.exs`
  - Job processes upload successfully
  - Job creates thumbnail file
  - Job retries on failure
  - Job fails after max attempts
  - Job handles missing photo

---

### Phase 5: LiveView UI (Days 13-20)

#### Step 5.1: Authentication Setup

**Configure ash_authentication_phoenix in router:**

**lib/lumina_web/router.ex:**
```elixir
defmodule LuminaWeb.Router do
  use LuminaWeb, :router
  use AshAuthentication.Phoenix.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {LuminaWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :load_from_session
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :load_from_bearer
  end

  scope "/", LuminaWeb do
    pipe_through :browser

    # Auth routes
    sign_in_route()
    sign_out_route AuthController
    auth_routes_for Lumina.Accounts.User, to: AuthController
    reset_route []

    # Public routes
    live "/share/:token", ShareLive.Show

    # Authenticated routes
    live_session :authenticated,
      on_mount: [{LuminaWeb.LiveUserAuth, :live_user_required}] do
      
      live "/", DashboardLive
      live "/orgs", OrgLive.Index
      live "/orgs/new", OrgLive.New
      live "/orgs/:org_slug", OrgLive.Show
      live "/orgs/:org_slug/albums/new", AlbumLive.New
      live "/orgs/:org_slug/albums/:album_id", AlbumLive.Show
      live "/orgs/:org_slug/albums/:album_id/upload", PhotoLive.Upload
      live "/orgs/:org_slug/albums/:album_id/share", AlbumLive.Share
      
      # Admin
      live "/admin/backup", AdminLive.Backup
    end
  end

  # Admin routes (if using ash_admin)
  if Mix.env() == :dev do
    import Phoenix.LiveDashboard.Router
    
    scope "/dev" do
      pipe_through :browser
      
      live_dashboard "/dashboard", metrics: LuminaWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
```

**Create LiveUserAuth module:**

**lib/lumina_web/live_user_auth.ex:**
```elixir
defmodule LuminaWeb.LiveUserAuth do
  import Phoenix.Component
  import Phoenix.LiveView

  def on_mount(:live_user_required, _params, session, socket) do
    socket = assign_current_user(socket, session)

    if socket.assigns.current_user do
      {:cont, socket}
    else
      {:halt, redirect(socket, to: "/sign-in")}
    end
  end

  defp assign_current_user(socket, session) do
    case session["user_token"] do
      nil ->
        assign(socket, :current_user, nil)
      
      token ->
        user = Lumina.Accounts.User.get_by_token(token)
        assign(socket, :current_user, user)
    end
  end
end
```

**Tests to write:**
- ✅ `test/lumina_web/auth_test.exs`
  - Sign up flow works
  - Sign in flow works
  - Sign out clears session
  - Protected routes redirect when not authenticated
  - Authenticated users can access dashboard

---

#### Step 5.2: Dashboard & Org Management

**lib/lumina_web/live/dashboard_live.ex:**
```elixir
defmodule LuminaWeb.DashboardLive do
  use LuminaWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    
    orgs = Lumina.Media.Org.for_user!(user.id, actor: user)

    {:ok, assign(socket, orgs: orgs)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <div class="sm:flex sm:items-center">
        <div class="sm:flex-auto">
          <h1 class="text-3xl font-bold text-gray-900">Your Organizations</h1>
          <p class="mt-2 text-sm text-gray-700">
            Manage your photo collections across different organizations.
          </p>
        </div>
        <div class="mt-4 sm:ml-16 sm:mt-0 sm:flex-none">
          <.link 
            navigate={~p"/orgs/new"} 
            class="inline-flex items-center justify-center rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500"
          >
            Create Organization
          </.link>
        </div>
      </div>

      <div class="mt-8 grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
        <%= for org <- @orgs do %>
          <.link 
            navigate={~p"/orgs/#{org.slug}"} 
            class="relative flex flex-col rounded-lg border border-gray-300 bg-white px-6 py-5 shadow-sm hover:border-gray-400 hover:shadow-md transition"
          >
            <h3 class="text-xl font-semibold text-gray-900"><%= org.name %></h3>
            <p class="mt-2 text-sm text-gray-500">
              View albums →
            </p>
          </.link>
        <% end %>
      </div>

      <%= if @orgs == [] do %>
        <div class="mt-8 text-center">
          <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
          </svg>
          <h3 class="mt-2 text-sm font-medium text-gray-900">No organizations</h3>
          <p class="mt-1 text-sm text-gray-500">Get started by creating a new organization.</p>
          <div class="mt-6">
            <.link 
              navigate={~p"/orgs/new"}
              class="inline-flex items-center rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500"
            >
              <svg class="-ml-0.5 mr-1.5 h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                <path d="M10.75 4.75a.75.75 0 00-1.5 0v4.5h-4.5a.75.75 0 000 1.5h4.5v4.5a.75.75 0 001.5 0v-4.5h4.5a.75.75 0 000-1.5h-4.5v-4.5z" />
              </svg>
              New Organization
            </.link>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
```

**lib/lumina_web/live/org_live/new.ex:**
```elixir
defmodule LuminaWeb.OrgLive.New do
  use LuminaWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: to_form(%{}, as: "org"))}
  end

  @impl true
  def handle_event("validate", %{"org" => org_params}, socket) do
    {:noreply, assign(socket, form: to_form(org_params, as: "org"))}
  end

  @impl true
  def handle_event("save", %{"org" => org_params}, socket) do
    user = socket.assigns.current_user
    
    case Lumina.Media.Org.create(
      org_params["name"],
      org_params["slug"],
      user.id,
      actor: user
    ) do
      {:ok, org} ->
        {:noreply, 
         socket
         |> put_flash(:info, "Organization created successfully")
         |> push_navigate(to: ~p"/orgs/#{org.slug}")}
      
      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, as: "org"))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto px-4 py-8">
      <h1 class="text-3xl font-bold text-gray-900 mb-6">Create Organization</h1>
      
      <.form 
        for={@form} 
        phx-submit="save" 
        phx-change="validate"
        class="space-y-6"
      >
        <div>
          <label for="org_name" class="block text-sm font-medium text-gray-700">
            Name
          </label>
          <input 
            type="text" 
            name="org[name]" 
            id="org_name"
            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
            required 
          />
        </div>
        
        <div>
          <label for="org_slug" class="block text-sm font-medium text-gray-700">
            Slug (URL-friendly name)
          </label>
          <input 
            type="text" 
            name="org[slug]" 
            id="org_slug"
            pattern="[a-z0-9-]+"
            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
            required 
          />
          <p class="mt-2 text-sm text-gray-500">
            Only lowercase letters, numbers, and hyphens allowed
          </p>
        </div>
        
        <div class="flex justify-end gap-3">
          <.link 
            navigate={~p"/"} 
            class="rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50"
          >
            Cancel
          </.link>
          <button 
            type="submit" 
            class="rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
          >
            Create Organization
          </button>
        </div>
      </.form>
    </div>
    """
  end
end
```

**Tests to write:**
- ✅ `test/lumina_web/live/dashboard_live_test.exs`
  - Dashboard shows user's orgs
  - Empty state shows when no orgs
  - Create org link works
- ✅ `test/lumina_web/live/org_live/new_test.exs`
  - Create new org
  - Slug validation works
  - User becomes owner of new org
  - Cancel redirects to dashboard

---

#### Step 5.3: Org & Album Views

**lib/lumina_web/live/org_live/show.ex:**
```elixir
defmodule LuminaWeb.OrgLive.Show do
  use LuminaWeb, :live_view

  @impl true
  def mount(%{"org_slug" => slug}, _session, socket) do
    user = socket.assigns.current_user
    
    org = Lumina.Media.Org.by_slug!(slug, actor: user, load: [:albums])

    {:ok, assign(socket, org: org, albums: org.albums)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto px-4 py-8">
      <div class="sm:flex sm:items-center">
        <div class="sm:flex-auto">
          <h1 class="text-3xl font-bold text-gray-900"><%= @org.name %></h1>
        </div>
        <div class="mt-4 sm:ml-16 sm:mt-0 flex gap-3">
          <.link 
            navigate={~p"/orgs/#{@org.slug}/albums/new"} 
            class="inline-flex items-center rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500"
          >
            New Album
          </.link>
        </div>
      </div>

      <div class="mt-8 grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
        <%= for album <- @albums do %>
          <.link 
            navigate={~p"/orgs/#{@org.slug}/albums/#{album.id}"} 
            class="group relative flex flex-col rounded-lg border border-gray-300 bg-white overflow-hidden shadow-sm hover:shadow-md transition"
          >
            <div class="aspect-square bg-gray-100 flex items-center justify-center">
              <svg class="h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
              </svg>
            </div>
            <div class="px-6 py-5">
              <h3 class="text-lg font-semibold text-gray-900"><%= album.name %></h3>
              <%= if album.description do %>
                <p class="mt-2 text-sm text-gray-600 line-clamp-2"><%= album.description %></p>
              <% end %>
            </div>
          </.link>
        <% end %>
      </div>

      <%= if @albums == [] do %>
        <div class="mt-8 text-center">
          <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
          </svg>
          <h3 class="mt-2 text-sm font-medium text-gray-900">No albums</h3>
          <p class="mt-1 text-sm text-gray-500">Get started by creating a new album.</p>
          <div class="mt-6">
            <.link 
              navigate={~p"/orgs/#{@org.slug}/albums/new"}
              class="inline-flex items-center rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500"
            >
              New Album
            </.link>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
```

**lib/lumina_web/live/album_live/new.ex:**
```elixir
defmodule LuminaWeb.AlbumLive.New do
  use LuminaWeb, :live_view

  @impl true
  def mount(%{"org_slug" => slug}, _session, socket) do
    user = socket.assigns.current_user
    org = Lumina.Media.Org.by_slug!(slug, actor: user)

    {:ok, assign(socket, org: org, form: to_form(%{}, as: "album"))}
  end

  @impl true
  def handle_event("validate", %{"album" => album_params}, socket) do
    {:noreply, assign(socket, form: to_form(album_params, as: "album"))}
  end

  @impl true
  def handle_event("save", %{"album" => album_params}, socket) do
    user = socket.assigns.current_user
    org = socket.assigns.org
    
    params = Map.put(album_params, "org_id", org.id)
    
    case Lumina.Media.Album.create(
      params["name"],
      org.id,
      actor: user
    ) do
      {:ok, album} ->
        {:noreply,
         socket
         |> put_flash(:info, "Album created successfully")
         |> push_navigate(to: ~p"/orgs/#{org.slug}/albums/#{album.id}")}
      
      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, as: "album"))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto px-4 py-8">
      <h1 class="text-3xl font-bold text-gray-900 mb-6">
        Create Album in <%= @org.name %>
      </h1>
      
      <.form 
        for={@form} 
        phx-submit="save" 
        phx-change="validate"
        class="space-y-6"
      >
        <div>
          <label for="album_name" class="block text-sm font-medium text-gray-700">
            Album Name
          </label>
          <input 
            type="text" 
            name="album[name]" 
            id="album_name"
            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
            required 
          />
        </div>
        
        <div>
          <label for="album_description" class="block text-sm font-medium text-gray-700">
            Description (optional)
          </label>
          <textarea 
            name="album[description]" 
            id="album_description"
            rows="3"
            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
          ></textarea>
        </div>
        
        <div class="flex justify-end gap-3">
          <.link 
            navigate={~p"/orgs/#{@org.slug}"} 
            class="rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50"
          >
            Cancel
          </.link>
          <button 
            type="submit" 
            class="rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500"
          >
            Create Album
          </button>
        </div>
      </.form>
    </div>
    """
  end
end
```

**Tests to write:**
- ✅ `test/lumina_web/live/org_live/show_test.exs`
  - Show org with albums
  - Only org members can view
  - Create album link works
  - Empty state for no albums
- ✅ `test/lumina_web/live/album_live/new_test.exs`
  - Create new album in org
  - Description is optional
  - Cancel redirects to org

---

#### Step 5.4: Photo Upload & Display

**lib/lumina_web/live/album_live/show.ex:**
```elixir
defmodule LuminaWeb.AlbumLive.Show do
  use LuminaWeb, :live_view
  
  alias Lumina.Media.Thumbnail

  @impl true
  def mount(%{"org_slug" => slug, "album_id" => album_id}, _session, socket) do
    user = socket.assigns.current_user
    
    org = Lumina.Media.Org.by_slug!(slug, actor: user)
    album = Ash.get!(Lumina.Media.Album, album_id, 
      tenant: org.id,
      actor: user,
      load: [:photos]
    )

    {:ok, assign(socket, org: org, album: album, photos: album.photos)}
  end

  @impl true
  def handle_event("delete_photo", %{"id" => photo_id}, socket) do
    user = socket.assigns.current_user
    
    photo = Ash.get!(Lumina.Media.Photo, photo_id, actor: user)
    
    # Delete files
    File.rm(photo.original_path)
    File.rm(photo.thumbnail_path)
    
    # Delete record
    Ash.destroy!(photo, actor: user)

    # Reload photos
    photos = Lumina.Media.Photo.for_album!(socket.assigns.album.id, actor: user)

    {:noreply, 
     socket
     |> assign(photos: photos)
     |> put_flash(:info, "Photo deleted")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto px-4 py-8">
      <div class="sm:flex sm:items-center">
        <div class="sm:flex-auto">
          <nav class="flex mb-4" aria-label="Breadcrumb">
            <ol class="flex items-center space-x-2">
              <li>
                <.link navigate={~p"/orgs/#{@org.slug}"} class="text-gray-500 hover:text-gray-700">
                  <%= @org.name %>
                </.link>
              </li>
              <li>
                <span class="text-gray-400">/</span>
              </li>
              <li class="text-gray-900 font-medium">
                <%= @album.name %>
              </li>
            </ol>
          </nav>
          
          <h1 class="text-3xl font-bold text-gray-900"><%= @album.name %></h1>
          <%= if @album.description do %>
            <p class="mt-2 text-gray-600"><%= @album.description %></p>
          <% end %>
        </div>
        <div class="mt-4 sm:ml-16 sm:mt-0 flex gap-3">
          <.link 
            navigate={~p"/orgs/#{@org.slug}/albums/#{@album.id}/share"}
            class="inline-flex items-center rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50"
          >
            Share
          </.link>
          <.link 
            navigate={~p"/orgs/#{@org.slug}/albums/#{@album.id}/upload"} 
            class="inline-flex items-center rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500"
          >
            Upload Photos
          </.link>
        </div>
      </div>

      <div class="mt-8">
        <%= if @photos == [] do %>
          <div class="text-center py-12">
            <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
            </svg>
            <h3 class="mt-2 text-sm font-medium text-gray-900">No photos</h3>
            <p class="mt-1 text-sm text-gray-500">Get started by uploading some photos.</p>
            <div class="mt-6">
              <.link 
                navigate={~p"/orgs/#{@org.slug}/albums/#{@album.id}/upload"}
                class="inline-flex items-center rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500"
              >
                Upload Photos
              </.link>
            </div>
          </div>
        <% else %>
          <div class="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4">
            <%= for photo <- @photos do %>
              <div class="group relative aspect-square">
                <img 
                  src={Thumbnail.thumbnail_url(photo.id, photo.filename)} 
                  alt={photo.filename}
                  class="h-full w-full object-cover rounded-lg"
                />
                <div class="absolute inset-0 bg-black bg-opacity-0 group-hover:bg-opacity-50 transition rounded-lg flex items-center justify-center">
                  <button 
                    phx-click="delete_photo" 
                    phx-value-id={photo.id}
                    data-confirm="Are you sure you want to delete this photo?"
                    class="hidden group-hover:block rounded-md bg-red-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-red-500"
                  >
                    Delete
                  </button>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
```

**lib/lumina_web/live/photo_live/upload.ex:**
```elixir
defmodule LuminaWeb.PhotoLive.Upload do
  use LuminaWeb, :live_view

  alias Lumina.Media.{Photo, Thumbnail}
  alias Lumina.Jobs.ProcessUpload

  @impl true
  def mount(%{"org_slug" => slug, "album_id" => album_id}, _session, socket) do
    user = socket.assigns.current_user
    
    org = Lumina.Media.Org.by_slug!(slug, actor: user)
    album = Ash.get!(Lumina.Media.Album, album_id, tenant: org.id, actor: user)

    socket = socket
             |> assign(org: org, album: album)
             |> allow_upload(:photos, 
                 accept: ~w(.jpg .jpeg .png .gif .webp),
                 max_entries: 10,
                 max_file_size: 10_000_000,
                 auto_upload: true)

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :photos, ref)}
  end

  @impl true
  def handle_event("save", _params, socket) do
    user = socket.assigns.current_user
    album = socket.assigns.album

    uploaded_files = consume_uploaded_entries(socket, :photos, fn %{path: path}, entry ->
      photo_id = Ash.UUID.generate()
      filename = entry.client_name
      
      original_path = Thumbnail.original_path(photo_id, filename)
      thumbnail_path = Thumbnail.thumbnail_path(photo_id, filename)
      
      # Ensure directories exist
      File.mkdir_p!(Path.dirname(original_path))
      File.mkdir_p!(Path.dirname(thumbnail_path))
      
      # Copy uploaded file
      File.cp!(path, original_path)
      
      # Create photo record
      {:ok, photo} = Photo
                     |> Ash.Changeset.for_create(:create, %{
                       filename: filename,
                       original_path: original_path,
                       thumbnail_path: thumbnail_path,
                       file_size: File.stat!(path).size,
                       content_type: entry.client_type,
                       album_id: album.id,
                       uploaded_by_id: user.id
                     }, actor: user)
                     |> Ash.create()
      
      # Queue thumbnail generation
      %{photo_id: photo.id}
      |> ProcessUpload.new()
      |> Oban.insert()
      
      {:ok, photo}
    end)

    {:noreply, 
     socket
     |> put_flash(:info, "#{length(uploaded_files)} photos uploaded successfully!")
     |> push_navigate(to: ~p"/orgs/#{socket.assigns.org.slug}/albums/#{album.id}")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto px-4 py-8">
      <h1 class="text-3xl font-bold text-gray-900 mb-6">
        Upload Photos to <%= @album.name %>
      </h1>
      
      <form id="upload-form" phx-submit="save" phx-change="validate">
        <div class="border-2 border-dashed border-gray-300 rounded-lg p-12 text-center hover:border-gray-400 transition">
          <svg class="mx-auto h-12 w-12 text-gray-400" stroke="currentColor" fill="none" viewBox="0 0 48 48">
            <path d="M28 8H12a4 4 0 00-4 4v20m32-12v8m0 0v8a4 4 0 01-4 4H12a4 4 0 01-4-4v-4m32-4l-3.172-3.172a4 4 0 00-5.656 0L28 28M8 32l9.172-9.172a4 4 0 015.656 0L28 28m0 0l4 4m4-24h8m-4-4v8m-12 4h.02" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />
          </svg>
          
          <div class="mt-4">
            <label for={@uploads.photos.ref} class="cursor-pointer">
              <span class="mt-2 block text-sm font-medium text-indigo-600 hover:text-indigo-500">
                Click to upload
              </span>
              <.live_file_input upload={@uploads.photos} class="sr-only" />
            </label>
            <p class="mt-1 text-xs text-gray-500">
              or drag and drop
            </p>
          </div>
          
          <p class="mt-2 text-xs text-gray-500">
            PNG, JPG, GIF, WebP up to 10MB (max 10 files)
          </p>
        </div>

        <%= for entry <- @uploads.photos.entries do %>
          <div class="mt-4 flex items-center gap-4 p-4 border border-gray-200 rounded-lg">
            <div class="flex-shrink-0">
              <.live_img_preview entry={entry} class="h-20 w-20 object-cover rounded" />
            </div>
            <div class="flex-1 min-w-0">
              <p class="text-sm font-medium text-gray-900 truncate">
                <%= entry.client_name %>
              </p>
              <p class="text-sm text-gray-500">
                <%= Float.round(entry.client_size / 1_000_000, 2) %> MB
              </p>
              <div class="mt-2">
                <div class="relative pt-1">
                  <div class="overflow-hidden h-2 text-xs flex rounded bg-gray-200">
                    <div 
                      style={"width: #{entry.progress}%"} 
                      class="shadow-none flex flex-col text-center whitespace-nowrap text-white justify-center bg-indigo-500 transition-all duration-300"
                    >
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <button 
              type="button" 
              phx-click="cancel-upload" 
              phx-value-ref={entry.ref}
              class="flex-shrink-0 text-red-600 hover:text-red-800"
            >
              <svg class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd" />
              </svg>
            </button>
          </div>

          <%= for err <- upload_errors(@uploads.photos, entry) do %>
            <p class="mt-2 text-sm text-red-600">
              <%= error_to_string(err) %>
            </p>
          <% end %>
        <% end %>

        <%= if length(@uploads.photos.entries) > 0 do %>
          <div class="mt-6 flex justify-end gap-3">
            <.link 
              navigate={~p"/orgs/#{@org.slug}/albums/#{@album.id}"}
              class="rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50"
            >
              Cancel
            </.link>
            <button 
              type="submit" 
              class="rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500"
            >
              Upload <%= length(@uploads.photos.entries) %> <%= if length(@uploads.photos.entries) == 1, do: "Photo", else: "Photos" %>
            </button>
          </div>
        <% end %>
      </form>
    </div>
    """
  end

  defp error_to_string(:too_large), do: "File is too large (max 10MB)"
  defp error_to_string(:not_accepted), do: "File type not accepted"
  defp error_to_string(:too_many_files), do: "Too many files (max 10)"
  defp error_to_string(_), do: "Unknown error"
end
```

**Tests to write:**
- ✅ `test/lumina_web/live/album_live/show_test.exs`
  - Show album with photos
  - Empty state for no photos
  - Delete photo works
  - Upload link works
  - Share link works
- ✅ `test/lumina_web/live/photo_live/upload_test.exs`
  - Upload single photo
  - Upload multiple photos
  - File size validation
  - File type validation
  - Cancel upload
  - Progress indicator

---

#### Step 5.5: Share Links

**lib/lumina_web/live/album_live/share.ex:**
```elixir
defmodule LuminaWeb.AlbumLive.Share do
  use LuminaWeb, :live_view

  @impl true
  def mount(%{"org_slug" => slug, "album_id" => album_id}, _session, socket) do
    user = socket.assigns.current_user
    
    org = Lumina.Media.Org.by_slug!(slug, actor: user)
    album = Ash.get!(Lumina.Media.Album, album_id, tenant: org.id, actor: user)
    
    {:ok, assign(socket, org: org, album: album, share_url: nil, form: to_form(%{}, as: "share"))}
  end

  @impl true
  def handle_event("create_link", params, socket) do
    user = socket.assigns.current_user
    album = socket.assigns.album
    
    days = String.to_integer(params["days"] || "7")
    expires_at = DateTime.utc_now() |> DateTime.add(days, :day)
    
    password_hash = if params["password"] != "" do
      Bcrypt.hash_pwd_salt(params["password"])
    else
      nil
    end
    
    {:ok, share_link} = Lumina.Media.ShareLink.create(
      %{
        expires_at: expires_at,
        password_hash: password_hash,
        album_id: album.id,
        created_by_id: user.id
      },
      actor: user
    )
    
    share_url = url(~p"/share/#{share_link.token}")
    
    {:noreply, 
     socket
     |> assign(share_url: share_url)
     |> put_flash(:info, "Share link created successfully")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto px-4 py-8">
      <h1 class="text-3xl font-bold text-gray-900 mb-6">
        Share <%= @album.name %>
      </h1>
      
      <.form for={@form} phx-submit="create_link" class="space-y-6">
        <div>
          <label for="days" class="block text-sm font-medium text-gray-700">
            Link expires in (days)
          </label>
          <input 
            type="number" 
            name="days" 
            id="days"
            value="7" 
            min="1" 
            max="365"
            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
          />
        </div>
        
        <div>
          <label for="password" class="block text-sm font-medium text-gray-700">
            Password (optional)
          </label>
          <input 
            type="password" 
            name="password" 
            id="password"
            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
          />
          <p class="mt-2 text-sm text-gray-500">
            Leave empty for public access
          </p>
        </div>
        
        <div class="flex justify-end gap-3">
          <.link 
            navigate={~p"/orgs/#{@org.slug}/albums/#{@album.id}"}
            class="rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50"
          >
            Cancel
          </.link>
          <button 
            type="submit" 
            class="rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500"
          >
            Generate Share Link
          </button>
        </div>
      </.form>

      <%= if @share_url do %>
        <div class="mt-8 rounded-md bg-green-50 p-4">
          <div class="flex">
            <div class="flex-shrink-0">
              <svg class="h-5 w-5 text-green-400" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
              </svg>
            </div>
            <div class="ml-3 flex-1">
              <h3 class="text-sm font-medium text-green-800">
                Share link created!
              </h3>
              <div class="mt-2">
                <div class="flex gap-2">
                  <input 
                    type="text" 
                    value={@share_url} 
                    readonly 
                    class="flex-1 rounded-md border-gray-300 bg-white shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                  />
                  <button 
                    type="button"
                    phx-click={JS.dispatch("phx:copy", to: "#share-url-input")}
                    class="rounded-md bg-green-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-green-500"
                  >
                    Copy
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
```

**lib/lumina_web/live/share_live/show.ex:**
```elixir
defmodule LuminaWeb.ShareLive.Show do
  use LuminaWeb, :live_view

  alias Lumina.Media.{ShareLink, Thumbnail}

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    case ShareLink.by_token(token) do
      {:ok, share_link} ->
        if DateTime.compare(share_link.expires_at, DateTime.utc_now()) == :lt do
          {:ok, assign(socket, error: "This link has expired", share_link: nil)}
        else
          # Load album with photos
          share_link = Ash.load!(share_link, album: :photos)
          
          # Increment view count
          ShareLink.increment_view_count!(share_link)
          
          {:ok, assign(socket, 
            share_link: share_link,
            album: share_link.album,
            photos: share_link.album.photos,
            password_required: !is_nil(share_link.password_hash),
            authenticated: is_nil(share_link.password_hash),
            error: nil
          )}
        end
      
      {:error, _} ->
        {:ok, assign(socket, error: "Invalid share link", share_link: nil)}
    end
  end

  @impl true
  def handle_event("check_password", %{"password" => password}, socket) do
    share_link = socket.assigns.share_link
    
    if Bcrypt.verify_pass(password, share_link.password_hash) do
      {:noreply, assign(socket, authenticated: true)}
    else
      {:noreply, put_flash(socket, :error, "Invalid password")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto px-4 py-8">
      <%= if @error do %>
        <div class="text-center py-12">
          <svg class="mx-auto h-12 w-12 text-red-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
          </svg>
          <h1 class="mt-4 text-2xl font-bold text-gray-900"><%= @error %></h1>
        </div>
      <% else %>
        <%= if @password_required and not @authenticated do %>
          <div class="max-w-md mx-auto">
            <div class="text-center mb-6">
              <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
              </svg>
              <h1 class="mt-4 text-2xl font-bold text-gray-900">Password Required</h1>
            </div>
            
            <form phx-submit="check_password" class="space-y-4">
              <div>
                <label for="password" class="sr-only">Password</label>
                <input 
                  type="password" 
                  name="password" 
                  id="password"
                  placeholder="Enter password" 
                  class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                  required
                  autofocus
                />
              </div>
              <button 
                type="submit" 
                class="w-full rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500"
              >
                Access Album
              </button>
            </form>
          </div>
        <% else %>
          <div class="mb-8">
            <h1 class="text-3xl font-bold text-gray-900"><%= @album.name %></h1>
            <%= if @album.description do %>
              <p class="mt-2 text-gray-600"><%= @album.description %></p>
            <% end %>
          </div>
          
          <div class="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4">
            <%= for photo <- @photos do %>
              <div class="aspect-square">
                <img 
                  src={Thumbnail.thumbnail_url(photo.id, photo.filename)} 
                  alt={photo.filename}
                  class="h-full w-full object-cover rounded-lg"
                />
              </div>
            <% end %>
          </div>

          <%= if @photos == [] do %>
            <div class="text-center py-12">
              <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
              </svg>
              <p class="mt-2 text-sm text-gray-500">This album is empty</p>
            </div>
          <% end %>
        <% end %>
      <% end %>
    </div>
    """
  end
end
```

**Tests to write:**
- ✅ `test/lumina_web/live/album_live/share_test.exs`
  - Create share link
  - Set expiration date
  - Optional password
  - Copy link to clipboard
- ✅ `test/lumina_web/live/share_live/show_test.exs`
  - Access shared album via token
  - Password protection works
  - Expired links show error
  - Invalid token shows error
  - View count increments

---

#### Step 5.6: Admin Backup Page

**lib/lumina_web/live/admin_live/backup.ex:**
```elixir
defmodule LuminaWeb.AdminLive.Backup do
  use LuminaWeb, :live_view

  @backup_password System.get_env("LUMINA_BACKUP_PASSWORD", "change-me-in-production")

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, authenticated: false, form: to_form(%{}, as: "auth"))}
  end

  @impl true
  def handle_event("authenticate", %{"password" => password}, socket) do
    if password == @backup_password do
      {:noreply, assign(socket, authenticated: true)}
    else
      {:noreply, 
       socket
       |> put_flash(:error, "Invalid password")
       |> assign(authenticated: false)}
    end
  end

  @impl true
  def handle_event("download_backup", _params, socket) do
    timestamp = DateTime.utc_now() |> Calendar.strftime("%Y%m%d_%H%M%S")
    backup_filename = "lumina_backup_#{timestamp}.tar.gz"
    backup_path = Path.join(System.tmp_dir!(), backup_filename)
    
    # Create tar.gz of database + uploads
    {_output, 0} = System.cmd("tar", [
      "-czf", backup_path,
      "-C", File.cwd!(),
      "lumina_dev.db",
      "lumina_dev.db-shm",
      "lumina_dev.db-wal",
      "priv/static/uploads"
    ], stderr_to_stdout: true)
    
    # Trigger download via JavaScript
    {:noreply, 
     push_event(socket, "trigger_download", %{
       url: ~p"/admin/backup/download/#{backup_filename}",
       filename: backup_filename
     })}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto px-4 py-8">
      <%= if @authenticated do %>
        <h1 class="text-3xl font-bold text-gray-900 mb-6">System Backup</h1>
        
        <div class="rounded-md bg-yellow-50 p-4 mb-6">
          <div class="flex">
            <div class="flex-shrink-0">
              <svg class="h-5 w-5 text-yellow-400" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd" />
              </svg>
            </div>
            <div class="ml-3">
              <h3 class="text-sm font-medium text-yellow-800">
                Warning
              </h3>
              <div class="mt-2 text-sm text-yellow-700">
                <p>
                  This will download a complete backup including:
                </p>
                <ul class="list-disc list-inside mt-2 space-y-1">
                  <li>SQLite database</li>
                  <li>All uploaded photos (originals + thumbnails)</li>
                </ul>
                <p class="mt-2">
                  The backup may be large depending on the number of photos stored.
                </p>
              </div>
            </div>
          </div>
        </div>
        
        <button 
          phx-click="download_backup"
          class="w-full rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500"
        >
          Download System Backup
        </button>
      <% else %>
        <h1 class="text-3xl font-bold text-gray-900 mb-6">Admin Access Required</h1>
        
        <.form for={@form} phx-submit="authenticate" class="space-y-4">
          <div>
            <label for="password" class="block text-sm font-medium text-gray-700">
              Admin Password
            </label>
            <input 
              type="password" 
              name="password" 
              id="password"
              class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
              required
              autofocus
            />
          </div>
          <button 
            type="submit" 
            class="w-full rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500"
          >
            Authenticate
          </button>
        </.form>
      <% end %>
    </div>
    """
  end
end
```

**Add download controller:**

**lib/lumina_web/controllers/admin_controller.ex:**
```elixir
defmodule LuminaWeb.AdminController do
  use LuminaWeb, :controller

  def download_backup(conn, %{"filename" => filename}) do
    backup_path = Path.join(System.tmp_dir!(), filename)
    
    if File.exists?(backup_path) do
      conn
      |> send_download({:file, backup_path}, filename: filename)
      |> halt()
    else
      conn
      |> put_status(404)
      |> text("Backup not found")
    end
  end
end
```

**Add route in router.ex:**
```elixir
scope "/admin", LuminaWeb do
  pipe_through :browser
  get "/backup/download/:filename", AdminController, :download_backup
end
```

**Add JavaScript hook for download:**

**assets/js/app.js:**
```javascript
let Hooks = {}

Hooks.DownloadBackup = {
  mounted() {
    this.handleEvent("trigger_download", ({url, filename}) => {
      const link = document.createElement('a')
      link.href = url
      link.download = filename
      document.body.appendChild(link)
      link.click()
      document.body.removeChild(link)
    })
  }
}

let liveSocket = new LiveSocket("/live", Socket, {
  params: {_csrf_token: csrfToken},
  hooks: Hooks
})
```

**Tests to write:**
- ✅ `test/lumina_web/live/admin_live/backup_test.exs`
  - Password protection works
  - Invalid password shows error
  - Backup creates tar.gz file
  - Backup includes database
  - Backup includes uploads
  - Download triggers correctly

---

### Phase 6: Deployment (Days 21-22)

#### Step 6.1: Production Configuration

**config/runtime.exs:**
```elixir
import Config

if config_env() == :prod do
  database_path =
    System.get_env("DATABASE_PATH") ||
    raise """
    environment variable DATABASE_PATH is missing.
    For example: /app/data/lumina.db
    """

  config :lumina, Lumina.Repo,
    database: database_path,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "5")

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
    raise """
    environment variable SECRET_KEY_BASE is missing.
    You can generate one by calling: mix phx.gen.secret
    """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :lumina, LuminaWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      ip: {0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base,
    server: true

  # Configure Oban for production
  config :lumina, Oban,
    repo: Lumina.Repo,
    queues: [media: 10],
    plugins: [
      Oban.Plugins.Pruner,
      {Oban.Plugins.Cron, crontab: []}
    ]
end
```

---

#### Step 6.2: Docker Setup

**Dockerfile:**
```dockerfile
# Build stage
FROM hexpm/elixir:1.17.3-erlang-27.1.2-alpine-3.20.3 AS build

# Install build dependencies
RUN apk add --no-cache \
    build-base \
    git \
    vips-dev \
    nodejs \
    npm

WORKDIR /app

# Install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Set build ENV
ENV MIX_ENV=prod

# Install mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only prod
RUN mix deps.compile

# Copy source
COPY config config
COPY lib lib
COPY priv priv

# Copy assets
COPY assets assets

# Install npm dependencies and compile assets
RUN cd assets && npm install
RUN mix assets.deploy

# Compile release
RUN mix compile
RUN mix release

# Runtime stage
FROM alpine:3.20.3

# Install runtime dependencies
RUN apk add --no-cache \
    openssl \
    ncurses-libs \
    vips \
    tar

WORKDIR /app

# Create non-root user
RUN adduser -D -h /app lumina
USER lumina

# Copy release from build stage
COPY --from=build --chown=lumina:lumina /app/_build/prod/rel/lumina ./

# Set environment
ENV HOME=/app
ENV MIX_ENV=prod
ENV PORT=4000

# Create data directories
RUN mkdir -p /app/data
RUN mkdir -p /app/priv/static/uploads/originals
RUN mkdir -p /app/priv/static/uploads/thumbnails

EXPOSE 4000

CMD ["bin/lumina", "start"]
```

**docker-compose.yml:**
```yaml
version: '3.8'

services:
  lumina:
    build: .
    container_name: lumina
    restart: unless-stopped
    ports:
      - "4000:4000"
    volumes:
      - ./data:/app/data
      - ./uploads:/app/priv/static/uploads
    environment:
      - SECRET_KEY_BASE=${SECRET_KEY_BASE}
      - DATABASE_PATH=/app/data/lumina.db
      - PHX_HOST=${PHX_HOST}
      - LUMINA_BACKUP_PASSWORD=${LUMINA_BACKUP_PASSWORD}
    networks:
      - web

  caddy:
    image: caddy:2-alpine
    container_name: caddy
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - caddy_data:/data
      - caddy_config:/config
    networks:
      - web

networks:
  web:

volumes:
  caddy_data:
  caddy_config:
```

**Caddyfile:**
```
{$PHX_HOST:lumina.example.com} {
    reverse_proxy lumina:4000
    
    # Optional: File size limit for uploads
    request_body {
        max_size 100MB
    }
}
```

**.env.example:**
```bash
# Generate with: mix phx.gen.secret
SECRET_KEY_BASE=your_secret_key_base_here

# Your domain
PHX_HOST=lumina.yourdomain.com

# Backup password
LUMINA_BACKUP_PASSWORD=your_backup_password_here
```

**.dockerignore:**
```
_build/
deps/
.git/
.gitignore
*.md
test/
.env
.env.*
!.env.example
```

---

#### Step 6.3: Deployment Instructions

**README_DEPLOYMENT.md:**
```markdown
# Lumina Deployment Guide

## Prerequisites

- Fedora VPS (Hetzner or similar)
- Docker & Docker Compose installed
- Domain configured in Cloudflare

## Initial Setup

### 1. Install Docker on Fedora

```bash
sudo dnf -y install dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo systemctl start docker
sudo systemctl enable docker
```

### 2. Clone Repository

```bash
git clone https://github.com/yourusername/lumina.git
cd lumina
```

### 3. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` and set:
- `SECRET_KEY_BASE` (generate with `mix phx.gen.secret`)
- `PHX_HOST` (your domain)
- `LUMINA_BACKUP_PASSWORD`

### 4. Build and Start

```bash
docker-compose up -d --build
```

### 5. Configure Cloudflare

1. Add A record pointing to your VPS IP
2. Enable Cloudflare proxy (orange cloud)
3. Set SSL/TLS to "Full"

### 6. Run Migrations

```bash
docker-compose exec lumina bin/lumina eval "Lumina.Release.migrate"
```

## Updating

```bash
git pull
docker-compose up -d --build
```

## Backups

Access `/admin/backup` and enter backup password to download.

## Logs

```bash
docker-compose logs -f lumina
```

## Troubleshooting

### Check if containers are running
```bash
docker-compose ps
```

### Restart services
```bash
docker-compose restart
```

### View database
```bash
docker-compose exec lumina bin/lumina remote
```
```

---

### Phase 7: Testing & Quality Assurance (Continuous)

#### Test Coverage Configuration

**mix.exs:**
```elixir
def project do
  [
    # ...
    test_coverage: [tool: ExCoveralls],
    preferred_cli_env: [
      coveralls: :test,
      "coveralls.detail": :test,
      "coveralls.post": :test,
      "coveralls.html": :test
    ]
  ]
end
```

**.coveralls.json:**
```json
{
  "coverage_options": {
    "minimum_coverage": 80
  },
  "skip_files": [
    "test/",
    "lib/lumina_web.ex",
    "lib/lumina_web/telemetry.ex"
  ]
}
```

#### Running Tests

```bash
# All tests
mix test

# With coverage
mix coveralls

# HTML coverage report
mix coveralls.html

# Watch mode (requires mix_test_watch)
mix test.watch

# Specific file
mix test test/lumina/media/photo_test.exs

# Code quality
mix credo --strict

# Type checking
mix dialyzer
```

---

## Summary & Timeline

### Total Estimated Time: 22 Days

| Phase | Days | Description |
|-------|------|-------------|
| Phase 1 | 1-2 | Project setup, dependencies |
| Phase 2 | 3-5 | Accounts domain (User, OrgMembership) |
| Phase 3 | 6-10 | Media domain (Org, Album, Photo, ShareLink) |
| Phase 4 | 11-12 | Image processing (thumbnails, Oban) |
| Phase 5 | 13-20 | LiveView UI (all pages) |
| Phase 6 | 21-22 | Deployment (Docker, Caddy) |
| Phase 7 | Continuous | Testing throughout |

### Key Deliverables

✅ Multi-organization photo sharing platform  
✅ User authentication & authorization  
✅ Album & photo management  
✅ Automatic thumbnail generation  
✅ Share links with expiration & passwords  
✅ Admin backup functionality  
✅ Docker deployment ready  
✅ 80%+ test coverage  

---

## Next Steps

1. ✅ Review this implementation plan
2. ✅ Initialize project with Igniter
3. ⏭️ Begin Phase 2: Accounts Domain
4. ⏭️ Test thoroughly at each phase
5. ⏭️ Deploy to staging environment
6. ⏭️ Production deployment

---

## Future Enhancements (Post-MVP)

- Email invitations for org members
- EXIF metadata extraction
- Face detection & tagging
- Advanced search & filtering
- Mobile app (React Native + API)
- S3-compatible object storage
- Multi-language support
- Activity audit log (via ash_paper_trail)
- Email notifications
- Public user profiles
- Commenting on photos
- Favorites/likes
- Download albums as ZIP
- Slideshows
- Photo editing (crop, rotate, filters)
