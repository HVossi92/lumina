defmodule Lumina.Release do
  @moduledoc """
  Used for executing DB release tasks when run in production without Mix
  installed.
  """
  require Ash.Query
  require Logger
  alias Lumina.Accounts.User

  @app :lumina

  def prepare do
    load_app()

    for repo <- repos() do
      case repo.__adapter__().storage_up(repo.config()) do
        :ok -> :ok
        {:error, :already_up} -> :ok
        {:error, reason} -> raise "Failed to create database: #{inspect(reason)}"
      end
    end

    migrate()
  end

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  def seeds do
    load_app()
    Application.ensure_all_started(@app)

    admin_email = System.get_env("LUMINA_ADMIN_EMAIL")
    admin_password = System.get_env("LUMINA_ADMIN_PASSWORD")

    cond do
      is_nil(admin_email) or admin_email == "" ->
        Logger.warning("LUMINA_ADMIN_EMAIL not set; skipping admin seed.")
        :ok

      is_nil(admin_password) or admin_password == "" ->
        Logger.warning("LUMINA_ADMIN_PASSWORD not set; skipping admin seed.")
        :ok

      true ->
        ensure_admin_user(admin_email, admin_password)
    end
  end

  defp ensure_admin_user(admin_email, admin_password) do
    case User |> Ash.Query.filter(email == ^admin_email) |> Ash.read(authorize?: false) do
      {:ok, [existing_user | _]} ->
        if existing_user.role != :admin do
          existing_user
          |> Ash.Changeset.for_update(:update, %{role: :admin})
          |> Ash.update(authorize?: false)
        end

        :ok

      {:ok, []} ->
        changeset =
          User
          |> Ash.Changeset.for_create(:register_with_password, %{
            email: admin_email,
            password: admin_password,
            password_confirmation: admin_password
          })
          |> Ash.Changeset.force_change_attribute(:role, :admin)

        case Ash.create(changeset, authorize?: false) do
          {:ok, _user} ->
            Logger.info("Admin user created: #{admin_email}")

          {:error, error} ->
            Logger.warning("Failed to create admin user: #{inspect(error)}")
        end

        :ok

      {:error, _} ->
        :ok
    end
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    # Many platforms require SSL when connecting to the database
    Application.ensure_all_started(:ssl)
    Application.ensure_loaded(@app)
  end
end
