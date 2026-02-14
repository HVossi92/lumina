defmodule LuminaWeb.OrgLive.New do
  use LuminaWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: to_form(%{}, as: "org"), page_title: "New Organization")}
  end

  @impl true
  def handle_event("validate", %{"org" => org_params}, socket) do
    {:noreply, assign(socket, form: to_form(org_params, as: "org"))}
  end

  @impl true
  def handle_event("save", %{"org" => org_params}, socket) do
    user = socket.assigns.current_user

    case Lumina.Media.Org.create(
           org_params["name"],
           org_params["slug"],
           user.id,
           actor: user
         ) do
      {:ok, org} ->
        {:noreply,
         socket
         |> put_flash(:info, "Organization created successfully")
         |> push_navigate(to: ~p"/orgs/#{org.slug}")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, as: "org"))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto px-4 py-8">
      <h1 class="text-3xl font-bold text-gray-900 mb-6">Create Organization</h1>

      <.form for={@form} id="org-form" phx-submit="save" phx-change="validate" class="space-y-6">
        <div>
          <label for="org_name" class="block text-sm font-medium text-gray-700">
            Name
          </label>
          <input
            type="text"
            name="org[name]"
            id="org_name"
            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
            required
          />
        </div>

        <div>
          <label for="org_slug" class="block text-sm font-medium text-gray-700">
            Slug (URL-friendly name)
          </label>
          <input
            type="text"
            name="org[slug]"
            id="org_slug"
            pattern="[a-z0-9-]+"
            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
            required
          />
          <p class="mt-2 text-sm text-gray-500">
            Only lowercase letters, numbers, and hyphens allowed
          </p>
        </div>

        <div class="flex justify-end gap-3">
          <.link
            navigate={~p"/"}
            class="rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50"
          >
            Cancel
          </.link>
          <button
            type="submit"
            class="rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
          >
            Create Organization
          </button>
        </div>
      </.form>
    </div>
    """
  end
end
