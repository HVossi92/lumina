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
    <div class="max-w-2xl mx-auto px-4 py-8">
      <h1 class="text-3xl font-bold text-gray-900 mb-6">
        Create Album in {@org.name}
      </h1>

      <.form for={@form} id="album-form" phx-submit="save" phx-change="validate" class="space-y-6">
        <div>
          <.input
            field={@form[:name]}
            type="text"
            label="Album Name"
            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
            required
          />
        </div>

        <div>
          <.input
            field={@form[:description]}
            type="textarea"
            label="Description (optional)"
            rows="3"
            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
          />
        </div>

        <div class="flex justify-end gap-3">
          <.link
            navigate={~p"/orgs/#{@org.slug}"}
            class="rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50"
          >
            Cancel
          </.link>
          <button
            type="submit"
            class="rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500"
          >
            Create Album
          </button>
        </div>
      </.form>
    </div>
    """
  end
end
