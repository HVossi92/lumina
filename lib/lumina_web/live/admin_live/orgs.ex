defmodule LuminaWeb.AdminLive.Orgs do
  @moduledoc """
  Admin-only: list, create, edit, delete organizations and generate invite links.
  Admins cannot access org content (albums/photos).
  """
  use LuminaWeb, :live_view

  alias Lumina.Accounts.OrgInvite
  alias Lumina.Media.Org

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    if user.role != :admin do
      {:halt,
       socket
       |> put_flash(:error, "Only administrators can access this page")
       |> Phoenix.LiveView.redirect(to: ~p"/")}
    else
      orgs = Ash.read!(Org, actor: user)
      orgs = Ash.load!(orgs, :memberships, authorize?: false)

      {:ok,
       assign(socket,
         orgs: orgs,
         form: nil,
         editing_org: nil,
         new_invite: nil,
         page_title: "Manage Organizations"
       )}
    end
  end

  @impl true
  def handle_event("new_org", _params, socket) do
    {:noreply,
     assign(socket,
       form: to_form(%{"name" => "", "slug" => ""}, as: "org"),
       editing_org: nil,
       new_invite: nil
     )}
  end

  @impl true
  def handle_event("edit_org", %{"id" => id}, socket) do
    org = Ash.get!(Org, id, actor: socket.assigns.current_user)

    {:noreply,
     assign(socket,
       form: to_form(%{"name" => org.name, "slug" => org.slug}, as: "org"),
       editing_org: org,
       new_invite: nil
     )}
  end

  @impl true
  def handle_event("cancel_form", _params, socket) do
    {:noreply,
     assign(socket,
       form: nil,
       editing_org: nil,
       new_invite: nil
     )}
  end

  @impl true
  def handle_event("validate_org", %{"org" => params}, socket) do
    current = socket.assigns.form.params
    merged = Map.merge(current, params)
    {:noreply, assign(socket, form: to_form(merged, as: "org"))}
  end

  @impl true
  def handle_event("save_org", %{"org" => params}, socket) do
    user = socket.assigns.current_user
    name = params["name"] || ""
    slug = params["slug"] || ""

    result =
      if socket.assigns.editing_org do
        org = socket.assigns.editing_org

        org
        |> Ash.Changeset.for_update(:update, %{name: name, slug: slug})
        |> Ash.update(actor: user)
      else
        Org.create(name, slug, actor: user)
      end

    case result do
      {:ok, _org} ->
        orgs = Ash.read!(Org, actor: user)
        orgs = Ash.load!(orgs, :memberships, authorize?: false)

        {:noreply,
         socket
         |> put_flash(:info, "Organization saved successfully")
         |> assign(orgs: orgs, form: nil, editing_org: nil, new_invite: nil)}

      {:error, error} ->
        {:noreply,
         socket
         |> put_flash(:error, Exception.message(error))
         |> assign(form: to_form(params, as: "org"))}
    end
  end

  @impl true
  def handle_event("delete_org", %{"id" => id}, socket) do
    user = socket.assigns.current_user
    org = Ash.get!(Org, id, actor: user)

    case Ash.destroy(org, actor: user) do
      :ok ->
        orgs = Ash.read!(Org, actor: user)
        orgs = Ash.load!(orgs, :memberships, authorize?: false)

        {:noreply,
         socket
         |> put_flash(:info, "Organization deleted")
         |> assign(orgs: orgs, form: nil, editing_org: nil, new_invite: nil)}

      {:error, error} ->
        {:noreply,
         socket
         |> put_flash(:error, Exception.message(error))}
    end
  end

  @impl true
  def handle_event("generate_invite", %{"id" => id, "role" => role}, socket) do
    user = socket.assigns.current_user
    org = Ash.get!(Org, id, actor: user)

    expires_at = DateTime.utc_now() |> DateTime.add(7, :day)

    role_atom =
      case role do
        "owner" -> :owner
        _ -> :member
      end

    case OrgInvite.create(org.id, role_atom, expires_at, actor: user) do
      {:ok, invite} ->
        base_url = LuminaWeb.Endpoint.url()
        join_url = "#{base_url}/join/#{invite.token}"

        {:noreply,
         assign(socket,
           new_invite: %{
             org: org,
             invite: invite,
             join_url: join_url,
             token: invite.token
           }
         )}

      {:error, error} ->
        {:noreply,
         socket
         |> put_flash(:error, Exception.message(error))}
    end
  end

  @impl true
  def handle_event("close_invite", _params, socket) do
    {:noreply, assign(socket, new_invite: nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-5xl mx-auto px-4 py-8">
      <div class="sm:flex sm:items-center sm:justify-between mb-8">
        <h1 class="text-3xl font-bold text-gray-900">Manage Organizations</h1>
        <div class="mt-4 sm:mt-0">
          <.link navigate={~p"/"} class="text-sm text-gray-500 hover:text-gray-700 mr-4">
            ← Dashboard
          </.link>
          <%= if !@form && !@editing_org do %>
            <button
              type="button"
              phx-click="new_org"
              class="rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500"
            >
              New Organization
            </button>
          <% end %>
        </div>
      </div>

      <%= if @form do %>
        <.form
          for={@form}
          id="org-form"
          phx-submit="save_org"
          phx-change="validate_org"
          class="mb-8 p-6 rounded-lg border border-gray-200 bg-gray-50"
        >
          <h2 class="text-lg font-semibold mb-4">
            {if @editing_org, do: "Edit Organization", else: "New Organization"}
          </h2>
          <div class="space-y-4">
            <.input
              field={@form[:name]}
              type="text"
              label="Name"
              class="block w-full rounded-md border-gray-300 shadow-sm"
            />
            <.input
              field={@form[:slug]}
              type="text"
              label="Slug"
              class="block w-full rounded-md border-gray-300 shadow-sm"
            />
          </div>
          <div class="mt-4 flex gap-3">
            <button
              type="submit"
              class="rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500"
            >
              Save
            </button>
            <button
              type="button"
              phx-click="cancel_form"
              class="rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50"
            >
              Cancel
            </button>
          </div>
        </.form>
      <% end %>

      <%= if @new_invite do %>
        <div class="mb-8 p-6 rounded-lg border-2 border-green-200 bg-green-50">
          <h3 class="text-lg font-semibold text-green-900 mb-2">Invite link created</h3>
          <p class="text-sm text-green-800 mb-2">
            Share this link with users to join <strong>{@new_invite.org.name}</strong>:
          </p>
          <div class="flex gap-2 items-center">
            <input
              type="text"
              readonly
              id="invite-url-input"
              value={@new_invite.join_url}
              class="flex-1 rounded-md border-gray-300 bg-white px-3 py-2 text-sm"
            />
            <button
              type="button"
              phx-click={JS.dispatch("phx:copy", to: "#invite-url-input")}
              class="rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white"
            >
              Copy
            </button>
          </div>
          <p class="mt-2 text-xs text-green-700">
            Or share the code: <code class="bg-green-100 px-1 rounded">{@new_invite.token}</code>
          </p>
          <button
            type="button"
            phx-click="close_invite"
            class="mt-4 text-sm text-green-700 hover:text-green-900"
          >
            Close
          </button>
        </div>
      <% end %>

      <div class="overflow-hidden shadow ring-1 ring-black ring-opacity-5 rounded-lg">
        <table class="min-w-full divide-y divide-gray-300">
          <thead class="bg-gray-50">
            <tr>
              <th class="px-4 py-3 text-left text-sm font-semibold text-gray-900">Name</th>
              <th class="px-4 py-3 text-left text-sm font-semibold text-gray-900">Slug</th>
              <th class="px-4 py-3 text-left text-sm font-semibold text-gray-900">Members</th>
              <th class="px-4 py-3 text-right text-sm font-semibold text-gray-900">Actions</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-200 bg-white">
            <%= for org <- @orgs do %>
              <tr>
                <td class="px-4 py-3 text-sm text-gray-900">{org.name}</td>
                <td class="px-4 py-3 text-sm text-gray-500">{org.slug}</td>
                <td class="px-4 py-3 text-sm text-gray-500">
                  {length(org.memberships || [])}
                </td>
                <td class="px-4 py-3 text-right text-sm">
                  <button
                    type="button"
                    phx-click="edit_org"
                    phx-value-id={org.id}
                    class="text-indigo-600 hover:text-indigo-900 mr-4"
                  >
                    Edit
                  </button>
                  <button
                    type="button"
                    phx-click="generate_invite"
                    phx-value-id={org.id}
                    phx-value-role="owner"
                    class="text-indigo-600 hover:text-indigo-900 mr-4"
                  >
                    Invite (owner)
                  </button>
                  <button
                    type="button"
                    phx-click="generate_invite"
                    phx-value-id={org.id}
                    phx-value-role="member"
                    class="text-indigo-600 hover:text-indigo-900 mr-4"
                  >
                    Invite (member)
                  </button>
                  <button
                    type="button"
                    phx-click="delete_org"
                    phx-value-id={org.id}
                    data-confirm="Delete this organization? This cannot be undone."
                    class="text-red-600 hover:text-red-900"
                  >
                    Delete
                  </button>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>

      <%= if @orgs == [] && !@form do %>
        <div class="mt-8 text-center text-gray-500">
          <p>No organizations yet. Create one to get started.</p>
        </div>
      <% end %>
    </div>
    """
  end
end
