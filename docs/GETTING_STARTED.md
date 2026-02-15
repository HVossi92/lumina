# Lumina - Getting Started Guide

Setup from scratch with Igniter. If you **cloned the repo**, use `mix setup` then `mix phx.server` (see README).

## Prerequisites

Install on your machine (Elixir ~> 1.15, Erlang/OTP 24+):

- **Elixir & Erlang:** [Install guide](https://elixir-lang.org/install.html) — macOS: `brew install elixir`; Ubuntu/Debian: `apt install elixir erlang`; Fedora: `dnf install elixir erlang`. Verify: `elixir --version`.
- **libvips** (image processing): macOS: `brew install vips`; Ubuntu/Debian: `apt install libvips-dev`; Fedora: `dnf install vips-devel`.

Assets use Mix (esbuild + Tailwind); Node.js is not required.

---

## Project Initialization

### 1. Install archives

```bash
mix archive.install hex igniter_new --force
mix archive.install hex phx_new 1.8.3 --force
```

### 2. Create project

```bash
mix igniter.new lumina --with phx.new --with-args "--database sqlite3" \
  --install ash,ash_phoenix --install ash_sqlite,ash_authentication \
  --install ash_authentication_phoenix,ash_admin \
  --install ash_oban,oban_web --install live_debugger,tidewave \
  --install ash_paper_trail --setup --yes
```

Creates Phoenix 1.8 + LiveView, SQLite, Ash (auth, admin, Oban, paper_trail), and dev tools.

### 3. Enter project and verify

```bash
cd lumina
mix deps.get
mix ecto.create
mix ecto.migrate
mix phx.server
```

Open http://localhost:4000. (If you used `--setup --yes`, DB may already exist; then `mix phx.server` is enough.)

---

## Next steps

Follow **LUMINA_IMPLEMENTATION_PLAN.md** starting at Phase 2 (Accounts domain). Add these deps to `mix.exs` when the plan says so:

```elixir
# In deps: image processing + testing/quality
{:vix, "~> 0.26"},
{:excoveralls, "~> 0.18", only: :test},
{:wallaby, "~> 0.30", only: :test, runtime: false},
{:credo, "~> 1.7", only: [:dev, :test], runtime: false},
{:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
```

Then `mix deps.get`. Generate migrations with `mix ash.codegen <domain>` (e.g. `accounts`), run with `mix ecto.migrate`.

---

## Commands (summary)

| Task           | Command                                                 |
| -------------- | ------------------------------------------------------- |
| Server         | `mix phx.server`                                        |
| Tests          | `mix test`, `mix coveralls`                             |
| Format         | `mix format`                                            |
| Quality        | `mix credo`, `mix dialyzer`                             |
| DB             | `mix ecto.create`, `mix ecto.migrate`, `mix ecto.reset` |
| Ash migrations | `mix ash.codegen <domain>`                              |
| IEx + server   | `iex -S mix phx.server`                                 |

See README “Useful commands” and `mix help` for more.

---

## Common issues

- **Port 4000 in use:** `lsof -ti:4000 | xargs kill -9` or `PORT=4001 mix phx.server`
- **Database locked (SQLite):** Stop Phoenix; remove `*.db-shm`, `*.db-wal` in project root.
- **Dependency conflicts:** Run `mix deps.get` and `mix compile`. Use `mix deps.clean --all` only as a last resort (project guideline: avoid unless necessary).

---

## Environment and Git

- **Local .env:** Copy `.env.example` to `.env`, set `SECRET_KEY_BASE`, `DATABASE_PATH`, `PHX_HOST`, `LUMINA_BACKUP_PASSWORD`. Load with `source .env` before `mix phx.server`.
- **.gitignore:** Phoenix generates one; ensure it includes `.env`, `*.db`, `*.db-shm`, `*.db-wal`, `/priv/static/uploads/`.

---

## Resources

- [Phoenix](https://hexdocs.pm/phoenix/overview.html) · [Ash](https://ash-hq.org/) · [LiveView](https://hexdocs.pm/phoenix_live_view/) · [Oban](https://hexdocs.pm/oban/) · [Vix](https://hexdocs.pm/vix/)
