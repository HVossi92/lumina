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
    {:noreply, assign(socket, form: to_form(album_params, as: "album"))}
  end

  @impl true
  def handle_event("save", %{"album" => album_params}, socket) do
    user = socket.assigns.current_user
    org = socket.assigns.org

    case Lumina.Media.Album.create(
           album_params["name"],
           org.id,
           actor: user,
           tenant: org.id
         ) do
      {:ok, album} ->
        {:noreply,
         socket
         |> put_flash(:info, "Album created successfully")
         |> push_navigate(to: ~p"/orgs/#{org.slug}/albums/#{album.id}")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, as: "album"))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto px-4 py-8">
      <h1 class="text-3xl font-bold text-gray-900 mb-6">
        Create Album in {@org.name}
      </h1>

      <.form for={@form} phx-submit="save" phx-change="validate" class="space-y-6">
        <div>
          <label for="album_name" class="block text-sm font-medium text-gray-700">
            Album Name
          </label>
          <input
            type="text"
            name="album[name]"
            id="album_name"
            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
            required
          />
        </div>

        <div>
          <label for="album_description" class="block text-sm font-medium text-gray-700">
            Description (optional)
          </label>
          <textarea
            name="album[description]"
            id="album_description"
            rows="3"
            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
          >
          </textarea>
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
