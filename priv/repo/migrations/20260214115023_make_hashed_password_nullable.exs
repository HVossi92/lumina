defmodule Lumina.Repo.Migrations.MakeHashedPasswordNullable do
  @moduledoc """
  Makes users.hashed_password nullable so OAuth-only users (e.g. Google) can exist.
  SQLite does not support ALTER COLUMN, so we recreate the users table.
  """

  use Ecto.Migration

  def up do
    # SQLite: recreate users table with hashed_password nullable
    execute("""
    CREATE TABLE users_new (
      id TEXT NOT NULL PRIMARY KEY,
      email TEXT NOT NULL,
      hashed_password TEXT,
      inserted_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
    """)

    execute("""
    INSERT INTO users_new (id, email, hashed_password, inserted_at, updated_at)
    SELECT id, email, hashed_password, inserted_at, updated_at FROM users
    """)

    execute("DROP TABLE users")
    execute("ALTER TABLE users_new RENAME TO users")
    create unique_index(:users, [:email], name: "users_unique_email_index")

    drop_if_exists unique_index(:share_links, [:org_id, :token],
                     name: "share_links_unique_token_index"
                   )

    create unique_index(:share_links, [:org_id, :token], name: "share_links_unique_token_index")
  end

  def down do
    drop_if_exists unique_index(:users, [:email], name: "users_unique_email_index")

    execute("""
    CREATE TABLE users_old (
      id TEXT NOT NULL PRIMARY KEY,
      email TEXT NOT NULL,
      hashed_password TEXT NOT NULL,
      inserted_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
    """)

    execute("""
    INSERT INTO users_old (id, email, hashed_password, inserted_at, updated_at)
    SELECT id, email, COALESCE(hashed_password, ''), inserted_at, updated_at FROM users
    """)

    execute("DROP TABLE users")
    execute("ALTER TABLE users_old RENAME TO users")
    create unique_index(:users, [:email], name: "users_unique_email_index")

    drop_if_exists unique_index(:share_links, [:org_id, :token],
                     name: "share_links_unique_token_index"
                   )

    create unique_index(:share_links, [:org_id, :token], name: "share_links_unique_token_index")
  end
end
