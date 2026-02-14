defmodule LuminaWeb.AlbumLive.New do
  use LuminaWeb, :live_view

  @impl true
  def mount(%{"org_slug" => slug}, _session, socket) do
    user = socket.assigns.current_user
    org = Lumina.Media.Org.by_slug!(slug, actor: user)

    {:ok, assign(socket, org: org, form: to_form(%{}, as: "album"), page_title: "New Album")}
  end

  @impl true
  def handle_event("validate", %{"album" => album_params}, socket) do
    current = socket.assigns.form.params
    merged = Map.merge(current, album_params)
    {:noreply, assign(socket, form: to_form(merged, as: "album"))}
  end

  @impl true
  def handle_event("save", %{"album" => album_params}, socket) do
    user = socket.assigns.current_user
    org = socket.assigns.org

    case Lumina.Media.Album
         |> Ash.Changeset.for_create(:create, %{
           name: album_params["name"],
           description: album_params["description"],
           org_id: org.id
         })
         |> Ash.create(actor: user, tenant: org.id) do
      {:ok, album} ->
        {:noreply,
         socket
         |> put_flash(:info, "Album created successfully")
         |> push_navigate(to: ~p"/orgs/#{org.slug}/albums/#{album.id}")}

      {:error, error} ->
        {:noreply,
         socket
         |> put_flash(:error, Exception.message(error))
         |> assign(form: to_form(album_params, as: "album"))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section>
      <h1 class="text-3xl font-serif font-bold text-base-content mb-6 text-balance">
        Create Album in {@org.name}
      </h1>

      <.form for={@form} id="album-form" phx-submit="save" phx-change="validate" class="space-y-6">
        <div class="form-control">
          <.input
            field={@form[:name]}
            type="text"
            label="Album Name"
            class="input input-bordered input-sm bg-base-200/60 border-base-300 text-base-content rounded-md w-full"
            required
          />
        </div>

        <div class="form-control">
          <.input
            field={@form[:description]}
            type="textarea"
            label="Description (optional)"
            rows="3"
            class="textarea textarea-bordered textarea-sm bg-base-200/60 border-base-300 text-base-content rounded-md w-full"
          />
        </div>

        <div class="flex justify-end gap-3">
          <.link navigate={~p"/orgs/#{@org.slug}"} class="btn btn-sm btn-ghost rounded-md">
            Cancel
          </.link>
          <button type="submit" class="btn btn-sm btn-accent rounded-md">
            Create Album
          </button>
        </div>
      </.form>
    </section>
    """
  end
end
