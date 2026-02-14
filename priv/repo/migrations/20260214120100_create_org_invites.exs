defmodule Lumina.Repo.Migrations.CreateOrgInvites do
  @moduledoc """
  Creates org_invites table for invite links and codes.
  """

  use Ecto.Migration

  def up do
    create table(:org_invites, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :org_id, references(:orgs, on_delete: :delete_all), null: false
      add :token, :string, null: false
      add :role, :string, null: false
      add :expires_at, :utc_datetime, null: false
      add :max_uses, :integer
      add :use_count, :integer, null: false, default: 0

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:org_invites, [:token], name: "org_invites_unique_token_index")
    create index(:org_invites, [:org_id])
  end

  def down do
    drop_if_exists index(:org_invites, [:org_id])
    drop_if_exists unique_index(:org_invites, [:token], name: "org_invites_unique_token_index")
    drop table(:org_invites)
  end
end
