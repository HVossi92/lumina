defmodule LuminaWeb.OrgLive.New do
  use LuminaWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    if user.role != :admin do
      {:halt,
       socket
       |> put_flash(:error, "Only administrators can create organizations")
       |> Phoenix.LiveView.redirect(to: ~p"/")}
    else
      {:ok, assign(socket, form: to_form(%{}, as: "org"), page_title: "New Organization")}
    end
  end

  @impl true
  def handle_event("validate", %{"org" => org_params}, socket) do
    current = socket.assigns.form.params
    merged = Map.merge(current, org_params)
    {:noreply, assign(socket, form: to_form(merged, as: "org"))}
  end

  @impl true
  def handle_event("save", %{"org" => org_params}, socket) do
    user = socket.assigns.current_user
    name = org_params["name"] || ""
    slug = org_params["slug"] || ""

    case Lumina.Media.Org.create(name, slug, actor: user) do
      {:ok, org} ->
        {:noreply,
         socket
         |> put_flash(:info, "Organization created successfully")
         |> push_navigate(to: ~p"/orgs/#{org.slug}")}

      {:error, error} ->
        {:noreply,
         socket
         |> put_flash(:error, Exception.message(error))
         |> assign(form: to_form(org_params, as: "org"))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section>
      <h1 class="text-3xl font-serif font-bold text-base-content mb-6 text-balance">
        Create Organization
      </h1>

      <.form for={@form} id="org-form" phx-submit="save" phx-change="validate" class="space-y-6">
        <div class="form-control">
          <.input
            field={@form[:name]}
            type="text"
            label="Name"
            class="input input-bordered input-sm bg-base-200/60 border-base-300 text-base-content rounded-md w-full"
            required
          />
        </div>

        <div class="form-control">
          <.input
            field={@form[:slug]}
            type="text"
            label="Slug (URL-friendly name)"
            pattern="[a-z0-9-]+"
            class="input input-bordered input-sm bg-base-200/60 border-base-300 text-base-content rounded-md w-full"
          />
          <p class="mt-2 text-sm text-base-content/40">
            Leave empty to generate from name. Only lowercase letters, numbers, and hyphens allowed.
          </p>
        </div>

        <div class="flex justify-end gap-3">
          <.link navigate={~p"/"} class="btn btn-sm btn-ghost rounded-md">
            Cancel
          </.link>
          <button type="submit" class="btn btn-sm btn-accent rounded-md">
            Create Organization
          </button>
        </div>
      </.form>
    </section>
    """
  end
end
