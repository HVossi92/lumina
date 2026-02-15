defmodule LuminaWeb.AdminLive.Users do
  @moduledoc """
  Admin-only: list and delete users (including other admins).
  Admins cannot delete themselves.
  """
  use LuminaWeb, :live_view

  alias Lumina.Accounts.User

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    if user.role != :admin do
      {:ok,
       socket
       |> put_flash(:error, "Only administrators can access this page")
       |> Phoenix.LiveView.redirect(to: ~p"/")}
    else
      users = Ash.read!(User, actor: user)

      {:ok,
       assign(socket,
         users: users,
         page_title: "Manage Users"
       )}
    end
  end

  @impl true
  def handle_event("delete_user", %{"id" => id}, socket) do
    user = socket.assigns.current_user
    target = Ash.get!(User, id, actor: user)

    case Ash.destroy(target, actor: user) do
      :ok ->
        users = Ash.read!(User, actor: user)

        {:noreply,
         socket
         |> put_flash(:info, "User deleted")
         |> assign(users: users)}

      {:error, error} ->
        message =
          case Exception.message(error) do
            "" -> "Could not delete user. They may have data that must be removed first."
            msg -> msg
          end

        {:noreply,
         socket
         |> put_flash(:error, message)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section>
      <div class="flex flex-wrap items-end justify-between gap-3 mb-8">
        <h1 class="text-3xl font-serif font-bold text-base-content text-balance">
          Manage Users
        </h1>
        <div class="flex items-center gap-2">
          <.link navigate={~p"/"} class="btn btn-ghost btn-sm rounded-md">
            ← Dashboard
          </.link>
        </div>
      </div>

      <div id="admin-users-table" class="overflow-hidden rounded-md border border-base-300">
        <table class="table">
          <thead>
            <tr>
              <th class="text-base-content">Email</th>
              <th class="text-base-content">Role</th>
              <th class="text-right text-base-content">Actions</th>
            </tr>
          </thead>
          <tbody>
            <%= for user <- @users do %>
              <tr id={"user-row-#{user.id}"}>
                <td class="text-base-content">{user.email}</td>
                <td class="text-base-content/60">{user.role}</td>
                <td class="text-right">
                  <%= if user.id != @current_user.id do %>
                    <button
                      type="button"
                      phx-click="delete_user"
                      phx-value-id={user.id}
                      data-confirm="Delete this user? This cannot be undone."
                      class="btn btn-ghost btn-xs text-error hover:text-error"
                    >
                      Delete
                    </button>
                  <% else %>
                    <span class="text-base-content/40 text-xs">(you)</span>
                  <% end %>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>

      <%= if @users == [] do %>
        <div class="mt-8 text-center text-base-content/40">
          <p>No users yet.</p>
        </div>
      <% end %>
    </section>
    """
  end
end
