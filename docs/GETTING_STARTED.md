# Lumina - Getting Started Guide

## Prerequisites Installation

Before running the Igniter command, you need to install the following on your local machine:

### 1. Install Elixir & Erlang

**On macOS (using Homebrew):**
```bash
brew install elixir
```

**On Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install elixir erlang
```

**On Fedora:**
```bash
sudo dnf install elixir erlang
```

**Verify installation:**
```bash
elixir --version
# Should show Elixir 1.17+ and Erlang/OTP 27+
```

### 2. Install Node.js (for Phoenix assets)

**On macOS:**
```bash
brew install node
```

**On Ubuntu/Debian:**
```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs
```

**On Fedora:**
```bash
sudo dnf install nodejs
```

### 3. Install libvips (for image processing)

**On macOS:**
```bash
brew install vips
```

**On Ubuntu/Debian:**
```bash
sudo apt-get install libvips-dev
```

**On Fedora:**
```bash
sudo dnf install vips-devel
```

---

## Project Initialization

### Step 1: Install Igniter and Phoenix Archives

```bash
# Install igniter_new
mix archive.install hex igniter_new --force

# Install Phoenix 1.8.3
mix archive.install hex phx_new 1.8.3 --force
```

### Step 2: Create Lumina Project

Run this command in your projects directory:

```bash
mix igniter.new lumina --with phx.new --with-args "--database sqlite3" \
  --install ash,ash_phoenix --install ash_sqlite,ash_authentication \
  --install ash_authentication_phoenix,ash_admin \
  --install ash_oban,oban_web --install live_debugger,tidewave \
  --install ash_paper_trail --setup --yes
```

This will:
- Create a new Phoenix 1.8 project with LiveView 1.1
- Set up SQLite as the database
- Install and configure all Ash framework components
- Install Oban for background jobs
- Set up authentication with ash_authentication
- Configure ash_admin for admin interface
- Add development tools (live_debugger, tidewave)

### Step 3: Navigate to Project

```bash
cd lumina
```

### Step 4: Verify Setup

```bash
# Install dependencies
mix deps.get

# Create database
mix ecto.create

# Run migrations (if any exist)
mix ecto.migrate

# Install Node.js dependencies
cd assets && npm install && cd ..

# Compile assets
mix assets.deploy
```

### Step 5: Start the Server

```bash
mix phx.server
```

Visit http://localhost:4000 - you should see the Phoenix welcome page.

---

## Project Structure After Initialization

```
lumina/
├── assets/               # Frontend assets
├── config/              # Application configuration
│   ├── config.exs       # General config
│   ├── dev.exs          # Development config
│   ├── test.exs         # Test config
│   └── runtime.exs      # Runtime config
├── lib/
│   ├── lumina/          # Domain logic
│   ├── lumina_web/      # Web interface
│   └── lumina.ex        # Application module
├── priv/
│   ├── repo/migrations/ # Database migrations
│   ├── static/          # Static files
│   └── gettext/         # Translations
├── test/                # Tests
├── .formatter.exs       # Code formatter config
├── .gitignore          
├── mix.exs              # Project dependencies
└── README.md
```

---

## Next Steps: Following the Implementation Plan

Now that your project is initialized, follow the implementation plan in `LUMINA_IMPLEMENTATION_PLAN.md`:

### Phase 2: Accounts Domain (Start Here)

1. **Create User Resource**
   ```bash
   # The file will be created at: lib/lumina/accounts/user.ex
   ```

2. **Create Token Resource**
   ```bash
   # The file will be created at: lib/lumina/accounts/token.ex
   ```

3. **Create OrgMembership Resource**
   ```bash
   # The file will be created at: lib/lumina/accounts/org_membership.ex
   ```

4. **Create Accounts Domain**
   ```bash
   # The file will be created at: lib/lumina/accounts.ex
   ```

5. **Generate Migrations**
   ```bash
   mix ash.codegen accounts
   ```

6. **Run Migrations**
   ```bash
   mix ecto.migrate
   ```

7. **Write Tests**
   ```bash
   # Create test files in test/lumina/accounts/
   mix test test/lumina/accounts/user_test.exs
   ```

### Additional Dependencies to Add

Edit `mix.exs` and add these to the `deps` function:

```elixir
defp deps do
  [
    # ... existing dependencies from igniter setup ...
    
    # Image processing
    {:vix, "~> 0.26"},
    
    # Testing
    {:excoveralls, "~> 0.18", only: :test},
    {:wallaby, "~> 0.30", only: :test, runtime: false},
    
    # Code quality
    {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
    {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
  ]
end
```

Then run:
```bash
mix deps.get
```

---

## Development Workflow

### Running Tests
```bash
# All tests
mix test

# Specific test file
mix test test/lumina/accounts/user_test.exs

# With coverage
mix coveralls

# Watch mode (install mix_test_watch first)
mix test.watch
```

### Code Quality
```bash
# Format code
mix format

# Check code quality
mix credo

# Type checking
mix dialyzer
```

### Database
```bash
# Create database
mix ecto.create

# Run migrations
mix ecto.migrate

# Rollback last migration
mix ecto.rollback

# Reset database (drop, create, migrate)
mix ecto.reset

# Generate new migration
mix ecto.gen.migration create_users
```

### Ash-Specific Commands
```bash
# Generate migrations from Ash resources
mix ash.codegen <domain_name>

# Example:
mix ash.codegen accounts

# Install Ash extension
mix igniter.install <package_name>
```

### Interactive Shell
```bash
# Start IEx with project loaded
iex -S mix

# Start Phoenix server in IEx
iex -S mix phx.server
```

---

## Common Issues & Solutions

### Issue: Port 4000 already in use
**Solution:**
```bash
# Kill process on port 4000
lsof -ti:4000 | xargs kill -9

# Or use a different port
PORT=4001 mix phx.server
```

### Issue: Database locked (SQLite)
**Solution:**
```bash
# Stop all running Phoenix servers
# Delete lock files
rm lumina_dev.db-shm lumina_dev.db-wal
```

### Issue: Node modules issues
**Solution:**
```bash
cd assets
rm -rf node_modules
npm install
cd ..
```

### Issue: Mix dependencies conflict
**Solution:**
```bash
# Clean build
mix deps.clean --all
mix deps.get
mix compile
```

---

## Environment Variables

Create a `.env` file for local development:

```bash
# .env (for local development)
export SECRET_KEY_BASE="generate_with_mix_phx_gen_secret"
export DATABASE_PATH="lumina_dev.db"
export PHX_HOST="localhost"
export LUMINA_BACKUP_PASSWORD="local-dev-password"
```

Load it with:
```bash
source .env
mix phx.server
```

---

## Git Setup

### Initialize Repository

```bash
git init
git add .
git commit -m "Initial commit: Lumina project setup with Ash Framework"
```

### Create .gitignore

The Phoenix generator should create a `.gitignore`, but ensure it includes:

```gitignore
# Database
*.db
*.db-shm
*.db-wal

# Elixir
/_build/
/deps/
*.ez
*.beam
/config/*.secret.exs
.fetch

# Phoenix
/priv/static/
/assets/node_modules/
npm-debug.log

# Environment
.env
.env.*
!.env.example

# Uploads (for local dev)
/priv/static/uploads/

# IDEs
.elixir_ls/
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
```

---

## Ready to Build!

You now have:
- ✅ A fully initialized Phoenix + Ash project
- ✅ All necessary dependencies installed
- ✅ Development environment configured
- ✅ Database ready
- ✅ Server running

Follow the **LUMINA_IMPLEMENTATION_PLAN.md** to start building the features:

1. Start with Phase 2: Accounts Domain
2. Write tests for each resource
3. Run migrations after creating resources
4. Move to Phase 3: Media Domain
5. Continue through all phases

---

## Questions Before Starting?

### Q: Do I need to use the exact versions?
**A:** Phoenix 1.8.0 and LiveView 1.1 are specified, but 1.8.3 is compatible. Stick with Elixir 1.17+ and OTP 27+.

### Q: Can I use PostgreSQL instead of SQLite?
**A:** Yes, but you'll need to:
1. Change `--database postgres` in the igniter command
2. Use `ash_postgres` instead of `ash_sqlite`
3. Update database configuration

### Q: Should I use ash_admin?
**A:** Yes, it's installed and will auto-generate an admin interface for your Ash resources. Very helpful for development.

### Q: What if I want to skip certain features?
**A:** The implementation plan is modular. You can skip ash_paper_trail or ash_admin if you don't need them. Just remove from the igniter command.

---

## Resources

- [Phoenix Guides](https://hexdocs.pm/phoenix/overview.html)
- [Ash Framework Docs](https://ash-hq.org/)
- [LiveView Docs](https://hexdocs.pm/phoenix_live_view/)
- [Oban Docs](https://hexdocs.pm/oban/)
- [Vix (libvips) Docs](https://hexdocs.pm/vix/)

Happy coding! 🚀
