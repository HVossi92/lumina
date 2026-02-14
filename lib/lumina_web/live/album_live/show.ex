defmodule LuminaWeb.AlbumLive.Show do
  use LuminaWeb, :live_view

  alias Lumina.Media.Thumbnail

  @impl true
  def mount(%{"org_slug" => slug, "album_id" => album_id}, _session, socket) do
    user = socket.assigns.current_user

    org = Lumina.Media.Org.by_slug!(slug, actor: user)

    album =
      Ash.get!(Lumina.Media.Album, album_id,
        tenant: org.id,
        actor: user,
        load: [:photos]
      )

    {:ok, assign(socket, org: org, album: album, photos: album.photos, page_title: album.name)}
  end

  @impl true
  def handle_event("delete_photo", %{"id" => photo_id}, socket) do
    user = socket.assigns.current_user

    org = socket.assigns.org
    photo = Ash.get!(Lumina.Media.Photo, photo_id, actor: user, tenant: org.id)

    # Delete files
    File.rm(photo.original_path)
    File.rm(photo.thumbnail_path)

    # Delete record
    Ash.destroy!(photo, actor: user, tenant: org.id)

    # Reload photos
    photos = Lumina.Media.Photo.for_album!(socket.assigns.album.id, actor: user, tenant: org.id)

    {:noreply,
     socket
     |> assign(photos: photos)
     |> put_flash(:info, "Photo deleted")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto px-4 py-8">
      <div class="sm:flex sm:items-center">
        <div class="sm:flex-auto">
          <nav class="flex mb-4" aria-label="Breadcrumb">
            <ol class="flex items-center space-x-2">
              <li>
                <.link navigate={~p"/orgs/#{@org.slug}"} class="text-gray-500 hover:text-gray-700">
                  {@org.name}
                </.link>
              </li>
              <li>
                <span class="text-gray-400">/</span>
              </li>
              <li class="text-gray-900 font-medium">
                {@album.name}
              </li>
            </ol>
          </nav>

          <h1 class="text-3xl font-bold text-gray-900">{@album.name}</h1>
          <%= if @album.description do %>
            <p class="mt-2 text-gray-600">{@album.description}</p>
          <% end %>
        </div>
        <div class="mt-4 sm:ml-16 sm:mt-0 flex gap-3">
          <.link
            navigate={~p"/orgs/#{@org.slug}/albums/#{@album.id}/share"}
            class="inline-flex items-center rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50"
          >
            Share
          </.link>
          <.link
            navigate={~p"/orgs/#{@org.slug}/albums/#{@album.id}/upload"}
            class="inline-flex items-center rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500"
          >
            Upload Photos
          </.link>
        </div>
      </div>

      <div class="mt-8">
        <%= if @photos == [] do %>
          <div class="text-center py-12">
            <svg
              class="mx-auto h-12 w-12 text-gray-400"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"
              />
            </svg>
            <h3 class="mt-2 text-sm font-medium text-gray-900">No photos</h3>
            <p class="mt-1 text-sm text-gray-500">Get started by uploading some photos.</p>
            <div class="mt-6">
              <.link
                navigate={~p"/orgs/#{@org.slug}/albums/#{@album.id}/upload"}
                class="inline-flex items-center rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500"
              >
                Upload Photos
              </.link>
            </div>
          </div>
        <% else %>
          <div class="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4">
            <%= for photo <- @photos do %>
              <div class="group relative aspect-square">
                <img
                  src={Thumbnail.thumbnail_url(photo.id, photo.filename)}
                  alt={photo.filename}
                  class="h-full w-full object-cover rounded-lg"
                />
                <div class="absolute inset-0 bg-black bg-opacity-0 group-hover:bg-opacity-50 transition rounded-lg flex items-center justify-center">
                  <button
                    phx-click="delete_photo"
                    phx-value-id={photo.id}
                    data-confirm="Are you sure you want to delete this photo?"
                    class="hidden group-hover:block rounded-md bg-red-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-red-500"
                  >
                    Delete
                  </button>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
