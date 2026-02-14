# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Lumina.Repo.insert!(%Lumina.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

require Ash.Query
alias Lumina.Accounts.User

admin_email = System.get_env("LUMINA_ADMIN_EMAIL")
admin_password = System.get_env("LUMINA_ADMIN_PASSWORD")

cond do
  is_nil(admin_email) or admin_email == "" ->
    raise "LUMINA_ADMIN_EMAIL must be set. Set it in .env or export it before running seeds."

  is_nil(admin_password) or admin_password == "" ->
    raise "LUMINA_ADMIN_PASSWORD must be set. Set it in .env or export it before running seeds."

  true ->
    :ok
end

# Create admin user if it doesn't exist
case User |> Ash.Query.filter(email == ^admin_email) |> Ash.read(authorize?: false) do
  {:ok, [existing_user | _]} ->
    # Ensure existing admin user has role set (for migrations from before role existed)
    if existing_user.role != :admin do
      existing_user
      |> Ash.Changeset.for_update(:update, %{role: :admin})
      |> Ash.update(authorize?: false)
    end

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
        IO.puts("Admin user created: #{admin_email}")
        IO.puts("Change the password in production via LUMINA_ADMIN_PASSWORD env var.")

      {:error, error} ->
        IO.warn("Failed to create admin user: #{inspect(error)}")
    end

  {:error, _} ->
    :ok
end
