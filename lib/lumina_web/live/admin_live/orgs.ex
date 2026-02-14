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
    <section>
      <div class="flex flex-wrap items-end justify-between gap-3 mb-8">
        <h1 class="text-3xl font-serif font-bold text-base-content text-balance">
          Manage Organizations
        </h1>
        <div class="flex items-center gap-2">
          <.link navigate={~p"/"} class="btn btn-ghost btn-sm rounded-md">
            ← Dashboard
          </.link>
          <%= if !@form && !@editing_org do %>
            <button
              type="button"
              phx-click="new_org"
              class="btn btn-sm btn-accent rounded-md"
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
          class="mb-8 p-6 rounded-md border border-base-300 bg-base-200"
        >
          <h2 class="text-lg font-serif font-semibold text-base-content mb-4">
            {if @editing_org, do: "Edit Organization", else: "New Organization"}
          </h2>
          <div class="space-y-4">
            <.input
              field={@form[:name]}
              type="text"
              label="Name"
            />
            <.input
              field={@form[:slug]}
              type="text"
              label="Slug"
            />
          </div>
          <div class="mt-4 flex gap-3">
            <button type="submit" class="btn btn-sm btn-accent rounded-md">
              Save
            </button>
            <button
              type="button"
              phx-click="cancel_form"
              class="btn btn-sm btn-ghost rounded-md"
            >
              Cancel
            </button>
          </div>
        </.form>
      <% end %>

      <%= if @new_invite do %>
        <div class="mb-8 alert alert-success rounded-md">
          <.icon name="hero-check-circle" class="size-5 shrink-0" />
          <div class="flex-1">
            <h3 class="font-semibold text-base-content">Invite link created</h3>
            <p class="text-sm mt-1">
              Share this link with users to join <strong>{@new_invite.org.name}</strong>:
            </p>
            <div class="flex gap-2 items-center mt-2">
              <input
                type="text"
                readonly
                id="invite-url-input"
                value={@new_invite.join_url}
                class="input input-bordered input-sm flex-1 bg-base-200/60 border-base-300 text-base-content rounded-md font-mono text-xs"
              />
              <button
                type="button"
                phx-click={JS.dispatch("phx:copy", to: "#invite-url-input")}
                class="btn btn-sm btn-success rounded-md"
              >
                Copy
              </button>
            </div>
            <p class="mt-2 text-xs text-base-content/70">
              Or share the code:
              <code class="bg-base-300 px-1 rounded font-mono">{@new_invite.token}</code>
            </p>
            <button
              type="button"
              phx-click="close_invite"
              class="mt-4 text-sm text-base-content/70 hover:text-base-content"
            >
              Close
            </button>
          </div>
        </div>
      <% end %>

      <div class="overflow-hidden rounded-md border border-base-300">
        <table class="table">
          <thead>
            <tr>
              <th class="text-base-content">Name</th>
              <th class="text-base-content">Slug</th>
              <th class="text-base-content">Members</th>
              <th class="text-right text-base-content">Actions</th>
            </tr>
          </thead>
          <tbody>
            <%= for org <- @orgs do %>
              <tr>
                <td class="text-base-content">{org.name}</td>
                <td class="text-base-content/60">{org.slug}</td>
                <td class="text-base-content/60">
                  {length(org.memberships || [])}
                </td>
                <td class="text-right">
                  <button
                    type="button"
                    phx-click="edit_org"
                    phx-value-id={org.id}
                    class="btn btn-ghost btn-xs text-accent hover:text-accent mr-2"
                  >
                    Edit
                  </button>
                  <button
                    type="button"
                    phx-click="generate_invite"
                    phx-value-id={org.id}
                    phx-value-role="owner"
                    class="btn btn-ghost btn-xs text-accent hover:text-accent mr-2"
                  >
                    Invite (owner)
                  </button>
                  <button
                    type="button"
                    phx-click="generate_invite"
                    phx-value-id={org.id}
                    phx-value-role="member"
                    class="btn btn-ghost btn-xs text-accent hover:text-accent mr-2"
                  >
                    Invite (member)
                  </button>
                  <button
                    type="button"
                    phx-click="delete_org"
                    phx-value-id={org.id}
                    data-confirm="Delete this organization? This cannot be undone."
                    class="btn btn-ghost btn-xs text-error hover:text-error"
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
        <div class="mt-8 text-center text-base-content/40">
          <p>No organizations yet. Create one to get started.</p>
        </div>
      <% end %>
    </section>
    """
  end
end
