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

    photos =
      (album.photos || [])
      |> Enum.sort_by(& &1.inserted_at, DateTime)

    {:ok,
     assign(socket,
       org: org,
       album: album,
       photos: photos,
       lightbox_index: nil,
       page_title: album.name
     )}
  end

  @impl true
  def handle_event("open_lightbox", %{"index" => index}, socket) do
    index = String.to_integer(index)
    max_index = max(0, length(socket.assigns.photos) - 1)
    index = min(max(index, 0), max_index)

    {:noreply, assign(socket, lightbox_index: index)}
  end

  def handle_event("close_lightbox", _params, socket) do
    {:noreply, assign(socket, lightbox_index: nil)}
  end

  def handle_event("lightbox_prev", _params, socket) do
    idx = socket.assigns.lightbox_index

    if idx && idx > 0,
      do: {:noreply, assign(socket, lightbox_index: idx - 1)},
      else: {:noreply, socket}
  end

  def handle_event("lightbox_next", _params, socket) do
    idx = socket.assigns.lightbox_index
    photos = socket.assigns.photos
    max_idx = max(0, length(photos) - 1)

    if idx != nil && idx < max_idx,
      do: {:noreply, assign(socket, lightbox_index: idx + 1)},
      else: {:noreply, socket}
  end

  def handle_event("lightbox_keydown", %{"key" => key}, socket) do
    idx = socket.assigns.lightbox_index
    photos = socket.assigns.photos
    max_idx = max(0, length(photos) - 1)

    {socket, _} =
      cond do
        key == "Escape" ->
          {assign(socket, lightbox_index: nil), nil}

        key == "ArrowLeft" && idx != nil && idx > 0 ->
          {assign(socket, lightbox_index: idx - 1), nil}

        key == "ArrowRight" && idx != nil && idx < max_idx ->
          {assign(socket, lightbox_index: idx + 1), nil}

        true ->
          {socket, nil}
      end

    {:noreply, socket}
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

    # Reload photos and sort; close lightbox when photos change
    photos =
      Lumina.Media.Photo.for_album!(socket.assigns.album.id, actor: user, tenant: org.id)
      |> Enum.sort_by(& &1.inserted_at, DateTime)

    {:noreply,
     socket
     |> assign(photos: photos, lightbox_index: nil)
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
          <div id="album-photos-grid" class="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4">
            <%= for {photo, idx} <- Enum.with_index(@photos) do %>
              <div class="group relative aspect-square overflow-hidden rounded-lg bg-gray-100">
                <button
                  type="button"
                  phx-click="open_lightbox"
                  phx-value-index={idx}
                  class="absolute inset-0 w-full h-full cursor-pointer focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-inset"
                  aria-label="View full size"
                >
                  <img
                    src={Thumbnail.thumbnail_url_from_path(photo.thumbnail_path)}
                    data-original-src={Thumbnail.original_url_from_path(photo.original_path)}
                    onerror="if(!this.dataset.fallbackAttempted){this.dataset.fallbackAttempted='true';this.src=this.dataset.originalSrc}"
                    alt={photo.filename}
                    class="h-full w-full object-cover pointer-events-none"
                  />
                </button>
                <div class="absolute inset-0 bg-black/0 group-hover:bg-black/50 transition rounded-lg flex items-center justify-center pointer-events-none">
                  <button
                    type="button"
                    phx-click="delete_photo"
                    phx-value-id={photo.id}
                    data-confirm="Are you sure you want to delete this photo?"
                    class="hidden group-hover:block rounded-md bg-red-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-red-500 pointer-events-auto"
                  >
                    Delete
                  </button>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>

      <%= if @lightbox_index != nil and @photos != [] do %>
        <% photo = Enum.at(@photos, @lightbox_index) %>
        <% total = length(@photos) %>
        <% current = @lightbox_index + 1 %>
        <div
          id="lightbox"
          phx-hook="LightboxKeys"
          role="dialog"
          aria-modal="true"
          aria-label="Photo viewer"
          class="fixed inset-0 z-50 flex items-center justify-center bg-black/90"
        >
          <div
            phx-click="close_lightbox"
            class="absolute inset-0"
            aria-hidden="true"
          />
          <div class="relative z-10 flex max-h-screen max-w-screen items-center justify-center p-4">
            <img
              src={Thumbnail.original_url_from_path(photo.original_path)}
              alt={photo.filename}
              class="max-h-[90vh] max-w-full object-contain"
            />
          </div>
          <button
            type="button"
            phx-click="close_lightbox"
            class="absolute right-4 top-4 z-20 rounded-full bg-white/10 p-2 text-white hover:bg-white/20 focus:outline-none focus:ring-2 focus:ring-white"
            aria-label="Close"
          >
            <.icon name="hero-x-mark" class="h-6 w-6" />
          </button>
          <%= if current > 1 do %>
            <button
              type="button"
              phx-click="lightbox_prev"
              class="absolute left-4 top-1/2 z-20 -translate-y-1/2 rounded-full bg-white/10 p-3 text-white hover:bg-white/20 focus:outline-none focus:ring-2 focus:ring-white"
              aria-label="Previous photo"
            >
              <.icon name="hero-chevron-left" class="h-8 w-8" />
            </button>
          <% end %>
          <%= if current < total do %>
            <button
              type="button"
              phx-click="lightbox_next"
              class="absolute right-4 top-1/2 z-20 -translate-y-1/2 rounded-full bg-white/10 p-3 text-white hover:bg-white/20 focus:outline-none focus:ring-2 focus:ring-white"
              aria-label="Next photo"
            >
              <.icon name="hero-chevron-right" class="h-8 w-8" />
            </button>
          <% end %>
          <p class="absolute bottom-4 left-1/2 z-20 -translate-x-1/2 rounded bg-black/50 px-3 py-1 text-sm text-white">
            {current} / {total}
          </p>
        </div>
      <% end %>
    </div>
    """
  end
end
