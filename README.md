# Lumina

Lumina is a multi-organization photo sharing app. Create organizations, add albums, upload photos, and share albums via time-limited or password-protected links.

---

## For users

### Getting started

1. Open the app in your browser (e.g. [http://localhost:4000](http://localhost:4000) in development).
2. **Sign up**: Click **Register** and create an account with email and password, or use **Sign in with Google** (see [Google OAuth setup](#google-oauth) below).
3. **Sign in**: Use **Sign in** with your email and password or **Sign in with Google**.

### Using Lumina

- **Dashboard** (home): After sign-in you see your organizations. Use **New organization** to create one (name + URL-friendly slug).
- **Organization**: Open an org to see its albums. Use **New Album** to add an album (name and optional description).
- **Album**: Open an album to see its photos. Use **Upload Photos** to add images (JPG, PNG, GIF, WebP; max 10 MB each, up to 10 files). Use **Share** to create a share link.
- **Share links**: You can set an expiry (days) and an optional password. Anyone with the link can view the album (and enter the password if you set one). Share links work without signing in.

### Sign out

Use **Sign out** in the navigation to log out.

---

## For admins

### Backup access

- Go to **/admin/backup** (you must be signed in).
- Enter the **backup password** (set by ops via `LUMINA_BACKUP_PASSWORD`).
- After authentication you can **Download System Backup**. The download includes the SQLite database and all uploaded photos (originals and thumbnails).

Use this for manual backups or to restore data on another instance.

---

## For ops

### Deploying Lumina

Lumina runs with **Docker** and **Caddy** as a reverse proxy. See [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) for the full guide (Fedora VPS, Hetzner, Cloudflare). Short version:

1. **Prerequisites**: Docker and Docker Compose on the host.
2. **Configure**: Copy `.env.example` to `.env` and set your secrets (the container loads `.env` via `env_file`; the app reads them at runtime in production):
   - `SECRET_KEY_BASE` — from `mix phx.gen.secret`
   - `TOKEN_SIGNING_SECRET` — from `mix phx.gen.secret`
   - `PHX_HOST` — your domain (e.g. `lumina.yourdomain.com`)
   - `LUMINA_BACKUP_PASSWORD` — password for the admin backup page
   - (Optional) `GOOGLE_OAUTH_CLIENT_ID` and `GOOGLE_OAUTH_CLIENT_SECRET` for [Google sign-in](#google-oauth)
3. **Run**:
   ```bash
   docker-compose up -d --build
   ```
4. **Migrations** (first run or after schema changes):
   ```bash
   docker-compose exec lumina bin/lumina eval "Lumina.Release.migrate"
   ```

### Where to store secrets (open source)

**Never commit secrets to the repository.** The app reads secrets from **environment variables** only; config files (e.g. `config/dev.exs`, `config/runtime.exs`) only reference `System.get_env(...)` and never contain real values.

- **Local development**: Copy `.env.example` to `.env`, fill in your values. `.env` is gitignored. Load it before starting the app (e.g. `source .env` or use a tool that loads `.env`).
- **Docker Compose**: The Lumina service uses `env_file: .env`, so all variables from `.env` are loaded into the container at runtime (the file is not copied into the image). Create `.env` from `.env.example` on the host; keep `.env` out of version control.
- **Production / other hosts**: Set the same variables in the environment (e.g. systemd, Kubernetes secrets, your host’s secret manager). Do not put production secrets in the repo or in `.env.example`.

`.env.example` documents variable names and purpose; it must only contain placeholders or be commented out, so the repo stays safe to publish.

### Environment variables

| Variable                     | Purpose                                                                                  |
| ---------------------------- | ---------------------------------------------------------------------------------------- |
| `SECRET_KEY_BASE`            | Phoenix session/encryption (generate with `mix phx.gen.secret`)                          |
| `TOKEN_SIGNING_SECRET`       | JWT signing for auth (generate with `mix phx.gen.secret`)                                |
| `DATABASE_PATH`              | SQLite DB path (default: `/app/data/lumina.db`)                                          |
| `PHX_HOST`                   | Public hostname                                                                          |
| `LUMINA_BACKUP_PASSWORD`     | Password for `/admin/backup`                                                             |
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

- **UI**: Register at `/register` (or use the sign-in page’s register link).
- **No seed users**: There are no default users; create one via the UI or add a seed in `priv/repo/seeds.exs` if you want.

### Tests and quality

```bash
mix test
```

Before committing, run the full precommit check (compile with warnings as errors, unlock unused deps, format, test):

```bash
mix precommit
```

### Tech stack

- **Phoenix** (LiveView), **Ash** (resources, policies, multitenancy), **AshAuthentication** (JWT/session)
- **SQLite** (AshSqlite), **Oban** (background jobs, e.g. thumbnail generation)
- **Tailwind CSS**, **libvips** (Vix) for image processing

### Project layout (high level)

- `lib/lumina/` — Domains: `Accounts` (User, Token, OrgMembership), `Media` (Org, Album, Photo, ShareLink), `Jobs` (ProcessUpload)
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

## Learn more

- [Phoenix deployment](https://hexdocs.pm/phoenix/deployment.html)
- [Phoenix guides](https://hexdocs.pm/phoenix/overview.html)
- [Ash Framework](https://ash-hq.org/)
- [Deployment guide for this app](docs/DEPLOYMENT.md)
