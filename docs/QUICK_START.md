# Lumina - Quick Start Reference

## Project initialization

Run this to create the Lumina project with Phoenix, Ash, SQLite, auth, Oban, and dev tools:

```bash
mix igniter.new lumina --with phx.new --with-args "--database sqlite3" \
  --install ash,ash_phoenix --install ash_sqlite,ash_authentication \
  --install ash_authentication_phoenix,ash_admin \
  --install ash_oban,oban_web --install live_debugger,tidewave \
  --install ash_paper_trail --setup --yes
```

**What it does:** Phoenix 1.8 + LiveView, SQLite, Ash (auth, admin, Oban, paper_trail). The `--setup --yes` flag runs deps and setup for you.

**Cloned the repo instead?** Use `mix setup` then `mix phx.server` — see [README](../README.md).

---

## Next steps

1. **Setup and verify:** [docs/GETTING_STARTED.md](GETTING_STARTED.md) — prerequisites, archives, verify, extra deps, commands.
2. **Implementation:** [docs/LUMINA_IMPLEMENTATION_PLAN.md](LUMINA_IMPLEMENTATION_PLAN.md) — start at Phase 2 (Accounts domain).

---

## Quick commands

```bash
cd lumina && mix phx.server    # run app
mix test                       # tests
mix ash.codegen accounts       # Ash migrations (then mix ecto.migrate)
mix ecto.reset                 # reset DB
mix precommit                  # format + test (before commit)
```

See README “Useful commands” and [GETTING_STARTED.md](GETTING_STARTED.md) for more.
