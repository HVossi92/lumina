# Lumina

Lumina is a multi-organization photo sharing app. Create organizations, add albums, upload photos, and share albums via time-limited or password-protected links.

---

## For users

### Getting started

1. Open the app in your browser (e.g. [http://localhost:4000](http://localhost:4000) in development).
2. **Sign up**: Click **Register** and create an account with email and password.
3. **Sign in**: Use **Sign in** with your email and password.

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
2. **Configure**: Copy `.env.example` to `.env` and set:
   - `SECRET_KEY_BASE` — from `mix phx.gen.secret`
   - `TOKEN_SIGNING_SECRET` — from `mix phx.gen.secret`
   - `PHX_HOST` — your domain (e.g. `lumina.yourdomain.com`)
   - `LUMINA_BACKUP_PASSWORD` — password for the admin backup page
3. **Run**:
   ```bash
   docker-compose up -d --build
   ```
4. **Migrations** (first run or after schema changes):
   ```bash
   docker-compose exec lumina bin/lumina eval "Lumina.Release.migrate"
   ```

### Environment variables

| Variable                 | Purpose                                                         |
| ------------------------ | --------------------------------------------------------------- |
| `SECRET_KEY_BASE`        | Phoenix session/encryption (generate with `mix phx.gen.secret`) |
| `TOKEN_SIGNING_SECRET`   | JWT signing for auth (generate with `mix phx.gen.secret`)       |
| `DATABASE_PATH`          | SQLite DB path (default: `/app/data/lumina.db`)                 |
| `PHX_HOST`               | Public hostname                                                 |
| `LUMINA_BACKUP_PASSWORD` | Password for `/admin/backup`                                    |
| `PORT`                   | App port (default: `4000`)                                      |
| `POOL_SIZE`              | DB pool size (default: `5`)                                     |

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
