# Lumina - Quick Start Reference

## Project Initialization Command

Run this single command to create the Lumina project with all dependencies:

```bash
mix igniter.new lumina --with phx.new --with-args "--database sqlite3" \
  --install ash,ash_phoenix --install ash_sqlite,ash_authentication \
  --install ash_authentication_phoenix,ash_admin \
  --install ash_oban,oban_web --install live_debugger,tidewave \
  --install ash_paper_trail --setup --yes
```

### What This Does:

| Component | Purpose |
|-----------|---------|
| `phx.new --database sqlite3` | Creates Phoenix 1.8 project with SQLite |
| `ash, ash_phoenix` | Core Ash Framework + Phoenix integration |
| `ash_sqlite` | Ash data layer for SQLite |
| `ash_authentication` | User authentication |
| `ash_authentication_phoenix` | Phoenix/LiveView auth components |
| `ash_admin` | Auto-generated admin interface |
| `ash_oban, oban_web` | Background jobs + web UI |
| `live_debugger` | LiveView debugging tools |
| `tidewave` | Additional dev tooling |
| `ash_paper_trail` | Audit logging |
| `--setup --yes` | Auto-run setup and accept defaults |

---

## Open Questions & Decisions

### 1. ✅ Phoenix & LiveView Versions
**Decision:** Phoenix 1.8.0, LiveView 1.1  
**Note:** Using `phx_new 1.8.3` is compatible and recommended (latest 1.8.x)

### 2. ✅ Multi-tenancy Naming
**Decision:** "Organizations" (shortened to "Org" in code)  
**Alternative considered:** Workspaces, Spaces, Vaults, Realms

### 3. ✅ User Invitation Method
**Decision:** Start with simple invite codes (no email required for MVP)  
**Future:** Add email invitations with Swoosh

### 4. ✅ Metadata Extraction
**Decision:** Skip for MVP, add later if needed  
**Note:** `exiftool_elixir` wrapper available when ready

### 5. ✅ Text File Support
**Decision:** Focus on images first (MVP)  
**Future:** Can add document support later

### 6. ✅ WYSIWYG Editor
**Decision:** Plain textarea for descriptions (MVP)  
**Future:** Add Tiptap or Quill if rich text needed

### 7. ✅ Permission Model
**Decision:** Simple two-tier (Owner + Member)
- **Owner:** Full control
- **Member:** Can view/upload/edit/delete all in org

### 8. ✅ Backup Strategy
**Decision:** Manual download via password-protected page  
**Note:** No automated backups in MVP (add later if needed)

---

## Additional Dependencies to Install

After running the igniter command, add these to `mix.exs`:

```elixir
# In the deps function, add:

# Image processing
{:vix, "~> 0.26"},

# Testing & Quality
{:excoveralls, "~> 0.18", only: :test},
{:wallaby, "~> 0.30", only: :test, runtime: false},
{:credo, "~> 1.7", only: [:dev, :test], runtime: false},
{:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
```

Then run:
```bash
mix deps.get
```

---

## Directory Structure to Create

After initialization, create these directories:

```bash
# Upload directories
mkdir -p priv/static/uploads/originals
mkdir -p priv/static/uploads/thumbnails

# Test support
mkdir -p test/support

# Jobs directory
mkdir -p lib/lumina/jobs
```

---

## Configuration Changes

### 1. Ash Domains Configuration

Add to `config/config.exs`:

```elixir
config :lumina,
  ash_domains: [Lumina.Accounts, Lumina.Media]

config :ash, :disable_async?, true # For SQLite
```

### 2. Oban Configuration

Add to `config/config.exs`:

```elixir
config :lumina, Oban,
  repo: Lumina.Repo,
  queues: [media: 10],
  plugins: [
    Oban.Plugins.Pruner,
    {Oban.Plugins.Cron, crontab: []}
  ]
```

Then add Oban to your supervision tree in `lib/lumina/application.ex`:

```elixir
children = [
  # ... existing children ...
  {Oban, Application.fetch_env!(:lumina, Oban)}
]
```

### 3. Test Coverage Configuration

Add to `mix.exs`:

```elixir
def project do
  [
    # ... existing config ...
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

Create `.coveralls.json`:

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

---

## First Steps After Initialization

### 1. Verify Setup
```bash
cd lumina
mix deps.get
mix ecto.create
cd assets && npm install && cd ..
mix phx.server
```

### 2. Create Upload Directories
```bash
mkdir -p priv/static/uploads/{originals,thumbnails}
```

### 3. Update .gitignore
Add:
```gitignore
# Uploads (for development)
/priv/static/uploads/

# Database
*.db-shm
*.db-wal
```

### 4. Set Up Environment Variables
Create `.env.example`:
```bash
SECRET_KEY_BASE=generate_with_mix_phx_gen_secret
DATABASE_PATH=lumina_dev.db
PHX_HOST=localhost
LUMINA_BACKUP_PASSWORD=local-dev-password
```

### 5. Run Tests
```bash
mix test
```

---

## Validation Checklist

Before starting implementation, verify:

- [ ] `mix phx.server` starts successfully
- [ ] Can visit http://localhost:4000
- [ ] `mix test` runs (even if no tests yet)
- [ ] All dependencies compile without errors
- [ ] Upload directories exist
- [ ] Database was created successfully
- [ ] Assets compile without errors

---

## Quick Commands Reference

```bash
# Start server
mix phx.server

# Interactive shell
iex -S mix phx.server

# Run tests
mix test

# Run specific test
mix test test/lumina/accounts/user_test.exs

# Format code
mix format

# Generate migrations from Ash resources
mix ash.codegen accounts

# Run migrations
mix ecto.migrate

# Rollback
mix ecto.rollback

# Reset database
mix ecto.reset

# Check code quality
mix credo

# Type checking
mix dialyzer

# Coverage report
mix coveralls.html
```

---

## Project Timeline Reminder

Following the implementation plan:

- **Days 1-2:** Project setup ← YOU ARE HERE
- **Days 3-5:** Accounts domain
- **Days 6-10:** Media domain
- **Days 11-12:** Image processing
- **Days 13-20:** LiveView UI
- **Days 21-22:** Deployment

**Total:** ~22 days for MVP

---

## Ready to Code?

1. Run the Igniter command above
2. Follow GETTING_STARTED.md for detailed setup
3. Follow LUMINA_IMPLEMENTATION_PLAN.md for implementation
4. Start with Phase 2: Accounts Domain

Questions? Check the FAQ in GETTING_STARTED.md or refer to:
- [Ash Framework Documentation](https://ash-hq.org/)
- [Phoenix Guides](https://hexdocs.pm/phoenix/)
- [Igniter Documentation](https://hexdocs.pm/igniter/)
