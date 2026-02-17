# Lumina

Lumina is a multi-organization photo sharing app. Create organizations, add albums, upload photos, and share albums via time-limited or password-protected links.

## Table of contents

- [What is Lumina?](#what-is-lumina)
- [Requirements](#requirements)
- [How to use Lumina](#how-to-use-lumina)
- [Docker build and deployment](#docker-build-and-deployment)
- [Tech stack](#tech-stack)
- [For admins](#for-admins)
- [For developers](#for-developers)
- [Documentation](#documentation)
- [Learn more](#learn-more)

---

## What is Lumina?

Lumina lets teams and families share photos in a simple, private way. You create **organizations** (e.g. “Family” or “Soccer Club”), add **albums** inside them, and **upload photos**. You can then **share** an album with anyone via a link—optionally with an expiry date and/or password—so they can view the photos without signing in. Regular users join organizations via invite links or codes from an administrator. **Sign-up is invite-only**: you need an invite link to create an account, and only **Sign in with Google** (OAuth) is available for new users. Administrators sign in with email and password (use the **Admin sign in** link on the sign-in page).

---

## Requirements

- **Elixir** ~> 1.15 and **Erlang/OTP** 24+
- **libvips** (for image processing and thumbnails)

Assets (JS/CSS) are built with the Hex-based **esbuild** and **Tailwind** Mix tasks; Node.js is not required for development or production builds.

For **Docker** deployment, only Docker and Docker Compose are required on the host; the image includes all runtime dependencies.

---

## How to use Lumina

### Getting started

1. Open the app in your browser (e.g. [http://localhost:4000](http://localhost:4000) in development).
2. **Sign up** (invite-only): Get an invite link from an administrator (e.g. `/join/TOKEN`). Open that link, then use **Sign in with Google** to create your account (see [Google OAuth setup](#google-oauth) below). Without an invite, new sign-ups are not allowed.
3. **Sign in**: Use **Sign in with Google**, or for administrators use **Admin sign in** (small link on the sign-in page) to sign in with email and password.

### Using the app

- **Dashboard** (home): After sign-in you see your organizations. Regular users **join** existing organizations via an invite link or code from an administrator. Only administrators can create new organizations.
- **Organization**: Open an org to see its albums. Use **New Album** to add an album (name and optional description).
- **Album**: Open an album to see its photos. Use **Upload Photos** to add images (JPG, PNG, GIF, WebP; max 10 MB each, up to 10 files). Use **Share** to create a share link.
- **Share links**: You can set an expiry (days) and an optional password. Anyone with the link can view the album (and enter the password if you set one). Share links work without signing in.

### Sign out

Use **Sign out** in the navigation to log out.

---

## Docker build and deployment

Lumina runs with **Docker** and **Caddy** as a reverse proxy. A full step-by-step guide (Fedora VPS, Hetzner, Cloudflare) is in [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md). Short version:

### Prerequisites

- Docker and Docker Compose on the host.

### Configure

1. Copy `.env.example` to `.env` on the host.
2. Set your secrets (the container loads `.env` via `env_file`; the app reads them at runtime in production):
   - `SECRET_KEY_BASE` — from `mix phx.gen.secret`
   - `TOKEN_SIGNING_SECRET` — from `mix phx.gen.secret`
   - `PHX_HOST` — your domain (e.g. `lumina.yourdomain.com`)
   - (Optional) `GOOGLE_OAUTH_CLIENT_ID` and `GOOGLE_OAUTH_CLIENT_SECRET` for [Google sign-in](#google-oauth)

### Build and run

```bash
docker-compose up -d --build
```

### Migrations (first run or after schema changes)

```bash
docker-compose exec lumina bin/lumina eval "Lumina.Release.migrate"
```

### Seeds (first run only)

After the first migration, create the admin user:

```bash
docker-compose exec lumina bin/lumina eval "Lumina.Release.seeds"
```

Set `LUMINA_ADMIN_EMAIL` and `LUMINA_ADMIN_PASSWORD` in `.env` (or in the Lumina service environment) before running seeds.

### Volume permissions

The Lumina container runs as a non-root user and needs write access to mounted volumes. Ensure `./data` and `./uploads` exist on the host and are writable by the container user (e.g. `chown 1000:1000 ./data ./uploads` if the container user has UID 1000).

### Where to store secrets (open source)

**Never commit secrets to the repository.** The app reads secrets from **environment variables** only; config files only reference `System.get_env(...)` and never contain real values.

- **Local development**: Copy `.env.example` to `.env`, fill in your values. `.env` is gitignored. Load it before starting the app (e.g. `source .env` or use a tool that loads `.env`).
- **Docker Compose**: The Lumina service uses `env_file: .env`, so all variables from `.env` are loaded into the container at runtime (the file is not copied into the image). Create `.env` from `.env.example` on the host; keep `.env` out of version control.
- **Production / other hosts**: Set the same variables in the environment (e.g. systemd, Kubernetes secrets, your host’s secret manager). Do not put production secrets in the repo or in `.env.example`.

`.env.example` documents variable names and purpose; it must only contain placeholders or be commented out, so the repo stays safe to publish.

### Environment variables

| Variable                     | Purpose                                                                                  |
| ---------------------------- | ---------------------------------------------------------------------------------------- |
| `LUMINA_ADMIN_EMAIL`         | Admin user email (seeded on first run; default: `admin@example.com`)                     |
| `LUMINA_ADMIN_PASSWORD`      | Admin user password (seeded on first run; default: `change-me-in-production`)            |
| `SECRET_KEY_BASE`            | Phoenix session/encryption (generate with `mix phx.gen.secret`)                          |
| `TOKEN_SIGNING_SECRET`       | JWT signing for auth (generate with `mix phx.gen.secret`)                                |
| `DATABASE_PATH`              | SQLite DB path (default: `/app/data/lumina.db`)                                          |
| `PHX_HOST`                   | Public hostname                                                                          |
| `PORT`                       | App port (default: `4000`)                                                               |
| `POOL_SIZE`                  | DB pool size (default: `5`)                                                              |
| `GOOGLE_OAUTH_CLIENT_ID`     | (Optional) Google OAuth client ID for “Sign in with Google”                              |
| `GOOGLE_OAUTH_CLIENT_SECRET` | (Optional) Google OAuth client secret                                                    |
| `GOOGLE_OAUTH_REDIRECT_URI`  | (Optional) Override redirect URI (default: `https://PHX_HOST/auth/user/google/callback`) |

### Google OAuth

You can enable **Sign in with Google** in development and production.

#### 1. Create OAuth credentials (Google Cloud Console)

1. Open [Google Cloud Console](https://console.cloud.google.com/) and select or create a project.
2. Go to **APIs & Services** → **OAuth consent screen** (left sidebar).
   - Choose **External** (or Internal for a Google Workspace org).
   - Fill in **App name**, **User support email**, and **Developer contact**. Save.
3. Go to **APIs & Services** → **Credentials** → **+ CREATE CREDENTIALS** → **OAuth client ID**.
   - Application type: **Web application**.
   - Name it (e.g. “Lumina”).
   - Under **Authorized redirect URIs**, click **+ ADD URI** and add:
     - Development: `http://localhost:4000/auth/user/google/callback`
     - Production: `https://YOUR_PHX_HOST/auth/user/google/callback` (replace with your real domain).
   - Create. Copy the **Client ID** and **Client secret**; you’ll use them in Lumina’s config.

#### 2. Test mode and whitelisting test users

New OAuth apps start in **Testing** mode. In this mode only **test users** can sign in; everyone else sees an error.

**To allow specific people to sign in while in Testing:**

1. In Google Cloud Console go to **APIs & Services** → **OAuth consent screen**.
2. In the **Test users** section click **+ ADD USERS**.
3. Add the **Google account email addresses** (e.g. `alice@gmail.com`) that should be able to use “Sign in with Google”.
4. Save. Those users can sign in; others cannot until you add them or publish the app.

**To allow anyone to sign in:** When you’re ready, use **PUBLISH APP** on the OAuth consent screen. That moves the app to **Production**. For the scopes Lumina uses (email, profile), you usually don’t need Google’s verification; verification is required only for certain sensitive or restricted scopes.

#### 3. Configure Lumina

- **Development**: set in `.env` or your shell:

  - `GOOGLE_OAUTH_CLIENT_ID` — from the OAuth client
  - `GOOGLE_OAUTH_CLIENT_SECRET` — from the OAuth client  
    The app uses `http://localhost:4000/auth/user/google/callback` as redirect URI in dev.

- **Production**: set the same variables in your deployment environment (e.g. `.env` for Docker). Redirect URI is derived from `PHX_HOST` unless you set `GOOGLE_OAUTH_REDIRECT_URI`.

If these are not set, the Google sign-in option is unavailable; email/password auth still works.

### Common ops tasks

- **Logs**: `docker-compose logs -f lumina`
- **Restart**: `docker-compose restart`
- **Update app**: `git pull` then `docker-compose up -d --build`
- **Backups**: Use `/admin/backup` or copy the `./data` and `./uploads` volumes

---

## Future improvements (audit backlog)

- **Session/LiveView signing salts**: Move from hardcoded values to env (e.g. `config/runtime.exs`). Ash Authentication uses the `AshAuthentication.Secret` behaviour for token signing; Phoenix session/live_view salts are separate and can follow the same pattern (fetch from Application config set from env).
- **Upload filename sanitization**: Sanitize `client_name` before storing (e.g. `Path.basename/1`, length limit, strip control chars).
- **Photos indexes**: Add `create index(:photos, [:org_id])` and `create index(:photos, [:album_id])` for query performance.
- **Backup async**: Run backup creation in a background process (e.g. Oban job) to avoid blocking the LiveView.

---

## Tech stack

- **Phoenix** (LiveView), **Ash** (resources, policies, multitenancy), **AshAuthentication** (JWT/session)
- **SQLite** (AshSqlite), **Oban** (background jobs, e.g. thumbnail generation)
- **Tailwind CSS**, **libvips** (Vix) for image processing

---

## For admins

### Administrator account

An administrator user is seeded on first run (see [Creating users (dev)](#creating-users-dev)). Use `LUMINA_ADMIN_EMAIL` and `LUMINA_ADMIN_PASSWORD` to configure the admin account (default: `admin@example.com` / `change-me-in-production`). **Change the password in production.**

Administrators can:

- **Create organizations** (regular users cannot)
- **Manage organizations** at `/admin/orgs`: list, edit, delete orgs, and **generate invite links/codes**
- **Invite users**: Share the invite link or code so users can join an organization

Administrators cannot access org content (albums/photos) unless they join an org via invite like any other user.

### Backup access

- Go to **/admin/backup** (you must be signed in as an administrator).
- Click **Download System Backup**. The download includes the SQLite database and all uploaded photos (originals and thumbnails).

Use this for manual backups or to restore data on another instance.

---

## For developers

### Setup

```bash
git clone <repo-url>
cd lumina
mix setup
```

This installs dependencies, creates the SQLite DB, runs migrations, and builds assets.

### Running the app

```bash
mix phx.server
```

Then open [http://localhost:4000](http://localhost:4000). Alternatively: `iex -S mix phx.server` for a REPL.

### Creating users (dev)

- **UI**: Register at `/register` (or use the sign-in page’s register link). Regular users join organizations via invite links or codes from an administrator.
- **Admin**: Run `mix run priv/repo/seeds.exs` to create the admin user. Configure via `LUMINA_ADMIN_EMAIL` and `LUMINA_ADMIN_PASSWORD` (defaults: `admin@example.com` / `change-me-in-production`). **Change these in production.**

### Tests and quality

```bash
mix test
```

Before committing, run the full precommit check (compile with warnings as errors, unlock unused deps, format, test):

```bash
mix precommit
```

### Project layout (high level)

- `lib/lumina/` — Domains: `Accounts` (User, Token, OrgMembership, OrgInvite), `Media` (Org, Album, Photo, ShareLink), `Jobs` (ProcessUpload)
- `lib/lumina_web/` — Router, LiveViews (dashboard, orgs, albums, photos, share, admin backup), auth overrides
- `priv/repo/migrations/` — Ecto/Ash migrations
- `test/` — ExUnit tests; use `Lumina.Fixtures` for test data

### Useful commands

| Command          | Description                                    |
| ---------------- | ---------------------------------------------- |
| `mix setup`      | Install deps, create DB, migrate, build assets |
| `mix phx.server` | Start server                                   |
| `mix test`       | Run tests                                      |
| `mix precommit`  | Compile, format, test (CI-style)               |
| `mix ecto.reset` | Drop DB, recreate, migrate, run seeds          |

---

## Documentation

- [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) — Step-by-step deployment (Fedora VPS, Docker, Caddy, Cloudflare)
- [docs/GETTING_STARTED.md](docs/GETTING_STARTED.md) — Setup from scratch with Igniter (prerequisites, init, verify)
- [docs/LUMINA_IMPLEMENTATION_PLAN.md](docs/LUMINA_IMPLEMENTATION_PLAN.md) — Full implementation plan and architecture reference
- [docs/QUICK_START.md](docs/QUICK_START.md) — Quick reference: igniter command and next steps

---

## Learn more

- [Phoenix deployment](https://hexdocs.pm/phoenix/deployment.html)
- [Phoenix guides](https://hexdocs.pm/phoenix/overview.html)
- [Ash Framework](https://ash-hq.org/)
