defmodule Lumina.Repo.Migrations.AddUserRole do
  @moduledoc """
  Adds role to users (admin | user). Default is user for existing and new users.
  Idempotent: skips adding the column if it already exists (e.g. after partial run).
  """

  use Ecto.Migration

  def up do
    try do
      alter table(:users) do
        add :role, :string, default: "user", null: false
      end
    rescue
      e in Exqlite.Error ->
        if String.contains?(Exception.message(e), "duplicate column") do
          :ok
        else
          reraise e, __STACKTRACE__
        end
    end

    # Backfill existing rows (SQLite ADD COLUMN with DEFAULT may not backfill in all versions)
    execute("UPDATE users SET role = 'user' WHERE role IS NULL")
  end

  def down do
    alter table(:users) do
      remove :role
    end
  end
end
