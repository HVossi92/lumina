defmodule LuminaWeb.AlbumLive.Show do
  use LuminaWeb, :live_view

  alias Lumina.Media.Photo
  alias Lumina.Media.Thumbnail

  @default_photo_limit 200

  @impl true
  def mount(%{"org_slug" => slug, "album_id" => album_id}, _session, socket) do
    user = socket.assigns.current_user

    case Lumina.Media.Org.by_slug(slug, actor: user) do
      {:ok, org} ->
        case Ash.get(Lumina.Media.Album, album_id, tenant: org.id, actor: user) do
          {:ok, album} ->
            load_album_content(socket, org, album, user, album_id)

          {:error, %Ash.Error.Forbidden{}} ->
            {:ok,
             socket
             |> put_flash(:error, "You don't have access to this album")
             |> Phoenix.LiveView.redirect(to: ~p"/orgs/#{slug}")}

          {:error, _} ->
            {:ok,
             socket
             |> put_flash(:error, "Album not found")
             |> Phoenix.LiveView.redirect(to: ~p"/orgs/#{slug}")}
        end

      {:error, %Ash.Error.Forbidden{}} ->
        {:ok,
         socket
         |> put_flash(:error, "You don't have access to this organization")
         |> Phoenix.LiveView.redirect(to: ~p"/")}

      {:error, _} ->
        {:ok,
         socket
         |> put_flash(:error, "Organization not found")
         |> Phoenix.LiveView.redirect(to: ~p"/")}
    end
  end

  defp load_album_content(socket, org, album, user, album_id) do
    photos_page =
      Photo
      |> Ash.Query.for_read(:for_album, %{album_id: album_id})
      |> Ash.Query.sort(:inserted_at)
      |> Ash.read!(actor: user, tenant: org.id, page: [limit: @default_photo_limit, offset: 0])

    photos = photos_page.results

    {:ok,
     assign(socket,
       org: org,
       album: album,
       photos: photos,
       photos_page: photos_page,
       search_query: "",
       open_menu_photo_id: nil,
       lightbox_index: nil,
       edit_tags_photo_id: nil,
       edit_tags_form: nil,
       rename_photo_id: nil,
       rename_form: nil,
       page_title: album.name
     )}
  end

  @impl true
  def handle_event("search", %{"q" => q}, socket) do
    {:noreply, assign(socket, search_query: String.trim(q))}
  end

  def handle_event("toggle_photo_menu", %{"id" => id}, socket) do
    current = socket.assigns.open_menu_photo_id
    open = if current == id, do: nil, else: id
    {:noreply, assign(socket, open_menu_photo_id: open)}
  end

  def handle_event("close_photo_menu", _params, socket) do
    {:noreply, assign(socket, open_menu_photo_id: nil)}
  end

  def handle_event("close_modal_escape", _params, socket) do
    socket =
      cond do
        socket.assigns.lightbox_index != nil ->
          assign(socket, lightbox_index: nil)

        socket.assigns.edit_tags_photo_id != nil ->
          assign(socket, edit_tags_photo_id: nil, edit_tags_form: nil)

        socket.assigns.rename_photo_id != nil ->
          assign(socket, rename_photo_id: nil, rename_form: nil)

        true ->
          socket
      end

    {:noreply, socket}
  end

  def handle_event("open_edit_tags", %{"id" => id}, socket) do
    case Enum.find(socket.assigns.photos, &(&1.id == id)) do
      nil ->
        {:noreply, socket}

      photo ->
        form = to_form(%{"tags" => Enum.join(photo.tags || [], ", ")}, as: "edit_tags")

        {:noreply,
         socket
         |> assign(open_menu_photo_id: nil)
         |> assign(edit_tags_photo_id: id)
         |> assign(edit_tags_form: form)}
    end
  end

  def handle_event("close_edit_tags", _params, socket) do
    {:noreply, assign(socket, edit_tags_photo_id: nil, edit_tags_form: nil)}
  end

  def handle_event("save_tags", %{"photo_id" => _id, "edit_tags" => edit_tags}, socket)
      when not is_map(edit_tags) do
    {:noreply, socket}
  end

  def handle_event("save_tags", %{"photo_id" => id, "edit_tags" => edit_tags}, socket)
      when is_map(edit_tags) do
    tags_str = Map.get(edit_tags, "tags")
    user = socket.assigns.current_user
    org = socket.assigns.org
    photo = Ash.get!(Photo, id, actor: user, tenant: org.id)

    tags =
      (tags_str || "")
      |> String.split(",")
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))
      |> Enum.uniq_by(&String.downcase/1)

    photo
    |> Ash.Changeset.for_update(:add_tags, %{tags: tags})
    |> Ash.update(actor: user, tenant: org.id)

    {photos, photos_page} = reload_photos_page(socket)

    {:noreply,
     socket
     |> assign(
       photos: photos,
       photos_page: photos_page,
       edit_tags_photo_id: nil,
       edit_tags_form: nil
     )
     |> put_flash(:info, "Tags updated")}
  end

  def handle_event("open_rename", %{"id" => id}, socket) do
    case Enum.find(socket.assigns.photos, &(&1.id == id)) do
      nil ->
        {:noreply, socket}

      photo ->
        form = to_form(%{"filename" => photo.filename}, as: "rename")

        {:noreply,
         socket
         |> assign(open_menu_photo_id: nil)
         |> assign(rename_photo_id: id)
         |> assign(rename_form: form)}
    end
  end

  def handle_event("close_rename", _params, socket) do
    {:noreply, assign(socket, rename_photo_id: nil, rename_form: nil)}
  end

  def handle_event(
        "rename_photo",
        %{"photo_id" => id, "rename" => %{"filename" => filename}},
        socket
      ) do
    user = socket.assigns.current_user
    org = socket.assigns.org
    photo = Ash.get!(Photo, id, actor: user, tenant: org.id)

    case photo
         |> Ash.Changeset.for_update(:rename, %{filename: String.trim(filename)})
         |> Ash.update(actor: user, tenant: org.id) do
      {:ok, _updated} ->
        {photos, photos_page} = reload_photos_page(socket)

        {:noreply,
         socket
         |> assign(
           photos: photos,
           photos_page: photos_page,
           rename_photo_id: nil,
           rename_form: nil
         )
         |> put_flash(:info, "Photo renamed")}

      {:error, error} ->
        message = Exception.message(error)
        form = to_form(%{"filename" => String.trim(filename)}, as: "rename")

        {:noreply,
         socket
         |> assign(rename_form: form)
         |> put_flash(:error, message)}
    end
  end

  @impl true
  def handle_event("open_lightbox", %{"index" => index}, socket) do
    index = String.to_integer(index)
    list = filter_photos(socket.assigns.photos, socket.assigns.search_query)
    max_index = max(0, length(list) - 1)
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
    list = filter_photos(socket.assigns.photos, socket.assigns.search_query)
    max_idx = max(0, length(list) - 1)

    if idx != nil && idx < max_idx,
      do: {:noreply, assign(socket, lightbox_index: idx + 1)},
      else: {:noreply, socket}
  end

  def handle_event("lightbox_keydown", %{"key" => key}, socket) do
    idx = socket.assigns.lightbox_index
    list = filter_photos(socket.assigns.photos, socket.assigns.search_query)
    max_idx = max(0, length(list) - 1)

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

    Ash.destroy!(photo, actor: user, tenant: org.id)

    {photos, photos_page} = reload_photos_page(socket)

    {:noreply,
     socket
     |> assign(photos: photos, photos_page: photos_page, lightbox_index: nil)
     |> put_flash(:info, "Photo deleted")}
  end

  defp reload_photos_page(socket) do
    user = socket.assigns.current_user
    org = socket.assigns.org
    album_id = socket.assigns.album.id
    page = socket.assigns.photos_page

    offset = if page, do: page.offset, else: 0

    photos_page =
      Photo
      |> Ash.Query.for_read(:for_album, %{album_id: album_id})
      |> Ash.Query.sort(:inserted_at)
      |> Ash.read!(
        actor: user,
        tenant: org.id,
        page: [limit: @default_photo_limit, offset: offset]
      )

    {photos_page.results, photos_page}
  end

  defp filter_photos(photos, search_query) do
    q = String.downcase(search_query || "")

    if q == "" do
      photos
    else
      Enum.filter(photos, fn photo ->
        filename_match = String.contains?(String.downcase(photo.filename || ""), q)

        tag_match =
          Enum.any?(photo.tags || [], fn tag -> String.contains?(String.downcase(tag), q) end)

        filename_match or tag_match
      end)
    end
  end

  @impl true
  def render(assigns) do
    filtered_photos = filter_photos(assigns.photos, assigns.search_query)
    assigns = assign(assigns, :filtered_photos, filtered_photos)

    ~H"""
    <section phx-click="close_photo_menu" phx-window-keydown="close_modal_escape" phx-key="Escape">
      <%= if @open_menu_photo_id do %>
        <div
          class="fixed inset-0 z-30"
          aria-hidden="true"
          phx-click="close_photo_menu"
        />
      <% end %>

      <div class="flex flex-wrap items-end justify-between gap-3 mb-8">
        <div>
          <nav class="flex mb-2" aria-label="Breadcrumb">
            <ol class="flex items-center gap-2 text-sm">
              <li>
                <.link
                  navigate={~p"/orgs/#{@org.slug}"}
                  class="text-base-content/60 hover:text-base-content"
                >
                  {@org.name}
                </.link>
              </li>
              <li class="text-base-content/40">/</li>
              <li class="text-base-content font-medium">
                {@album.name}
              </li>
            </ol>
          </nav>
          <h1 class="text-3xl font-serif font-bold text-base-content text-balance">
            {@album.name}
          </h1>
          <%= if @album.description do %>
            <p class="mt-2 text-base-content/60">{@album.description}</p>
          <% end %>
        </div>
        <div class="flex flex-wrap items-center gap-2">
          <form id="album-search-form" phx-change="search" class="flex-1 min-w-[200px] max-w-xs">
            <input
              type="search"
              name="q"
              value={@search_query}
              placeholder="Search photos..."
              phx-debounce="200"
              class="input input-bordered input-sm bg-base-200/60 border-base-300 text-base-content rounded-md w-full"
            />
          </form>
          <.link
            navigate={~p"/orgs/#{@org.slug}/albums/#{@album.id}/share"}
            class="btn btn-sm btn-ghost rounded-md"
          >
            Share
          </.link>
          <.link
            navigate={~p"/orgs/#{@org.slug}/albums/#{@album.id}/upload"}
            class="btn btn-sm btn-accent gap-1.5 rounded-md"
          >
            <.icon name="hero-arrow-up-tray" class="size-4" /> Upload Photos
          </.link>
        </div>
      </div>

      <div>
        <%= if @filtered_photos == [] do %>
          <div class="flex flex-col items-center justify-center py-16 text-center">
            <div class="bg-base-300 rounded-full p-4 mb-4">
              <.icon name="hero-photo" class="size-8 text-base-content/30" />
            </div>
            <%= if String.trim(@search_query || "") != "" do %>
              <h3 class="text-lg font-serif font-semibold text-base-content mb-1">
                No photos match your search
              </h3>
              <p class="text-sm text-base-content/40 mb-4 max-w-xs">
                Try different search terms or clear the search to see all photos.
              </p>
            <% else %>
              <h3 class="text-lg font-serif font-semibold text-base-content mb-1">
                No photos yet
              </h3>
              <p class="text-sm text-base-content/40 mb-4 max-w-xs">
                Get started by uploading some photos.
              </p>
              <.link
                navigate={~p"/orgs/#{@org.slug}/albums/#{@album.id}/upload"}
                class="btn btn-sm btn-accent gap-1.5 rounded-md"
              >
                <.icon name="hero-arrow-up-tray" class="size-4" /> Upload Photos
              </.link>
            <% end %>
          </div>
        <% else %>
          <div
            id="album-photos-grid"
            class={[
              "grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4",
              @open_menu_photo_id && "relative z-40"
            ]}
          >
            <%= for {photo, idx} <- Enum.with_index(@filtered_photos) do %>
              <div class="group relative aspect-square overflow-hidden rounded-md bg-base-300">
                <button
                  type="button"
                  phx-click="open_lightbox"
                  phx-value-index={idx}
                  class="absolute inset-0 w-full h-full cursor-pointer focus:outline-none focus:ring-2 focus:ring-accent focus:ring-inset"
                  aria-label="View full size"
                >
                  <img
                    src={Thumbnail.thumbnail_url_from_path(photo.thumbnail_path)}
                    data-original-src={Thumbnail.original_url_from_path(photo.original_path)}
                    onerror="if(!this.dataset.fallbackAttempted){this.dataset.fallbackAttempted='true';this.src=this.dataset.originalSrc}"
                    alt={photo.filename}
                    class="h-full w-full object-cover group-hover:scale-[1.03] transition-transform duration-500 ease-out pointer-events-none"
                  />
                </button>
                <%= if (photo.tags || []) != [] do %>
                  <div class="absolute bottom-0 left-0 right-0 z-[5] flex flex-wrap gap-1 p-2 bg-gradient-to-t from-black/70 to-transparent">
                    <%= for tag <- Enum.take(photo.tags, 4) do %>
                      <span class="inline-flex items-center rounded-md bg-base-100/90 px-1.5 py-0.5 text-xs text-base-content">
                        {tag}
                      </span>
                    <% end %>
                    <%= if length(photo.tags || []) > 4 do %>
                      <span class="inline-flex items-center rounded-md bg-base-100/90 px-1.5 py-0.5 text-xs text-base-content/70">
                        +{length(photo.tags) - 4}
                      </span>
                    <% end %>
                  </div>
                <% end %>
                <div class="absolute top-2 right-2 z-10">
                  <button
                    type="button"
                    phx-click="toggle_photo_menu"
                    phx-value-id={photo.id}
                    class="btn btn-ghost btn-sm btn-square rounded-md bg-base-content/20 hover:bg-base-content/40 text-base-100"
                    aria-label="Photo menu"
                  >
                    <.icon name="hero-ellipsis-vertical" class="size-5" />
                  </button>
                  <%= if @open_menu_photo_id == photo.id do %>
                    <div class="absolute right-0 top-full mt-1 py-1 min-w-[140px] rounded-md bg-base-100 border border-base-300 shadow-lg z-40 text-base-content">
                      <button
                        type="button"
                        phx-click="open_rename"
                        phx-value-id={photo.id}
                        class="flex items-center gap-2 w-full text-left px-3 py-2 text-sm hover:bg-base-200 rounded"
                      >
                        <.icon name="hero-pencil-square" class="size-4" /> Rename
                      </button>
                      <button
                        type="button"
                        phx-click="open_edit_tags"
                        phx-value-id={photo.id}
                        class="flex items-center gap-2 w-full text-left px-3 py-2 text-sm hover:bg-base-200 rounded"
                      >
                        <.icon name="hero-tag" class="size-4" /> Edit tags
                      </button>
                      <a
                        href={Thumbnail.original_url_from_path(photo.original_path)}
                        download={photo.filename}
                        class="flex items-center gap-2 w-full text-left px-3 py-2 text-sm hover:bg-base-200 rounded"
                      >
                        <.icon name="hero-arrow-down-tray" class="size-4" /> Download
                      </a>
                      <button
                        type="button"
                        phx-click="delete_photo"
                        phx-value-id={photo.id}
                        data-confirm="Are you sure you want to delete this photo?"
                        class="flex items-center gap-2 w-full text-left px-3 py-2 text-sm text-error hover:bg-base-200 rounded"
                      >
                        <.icon name="hero-trash" class="size-4" /> Delete
                      </button>
                    </div>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>

      <%= if @edit_tags_photo_id do %>
        <div
          id="edit-tags-modal"
          class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4"
          role="dialog"
          aria-modal="true"
          aria-labelledby="edit-tags-title"
        >
          <div
            phx-click="close_edit_tags"
            class="absolute inset-0"
            aria-hidden="true"
          />
          <div
            class="relative z-10 w-full max-w-md rounded-lg bg-base-100 p-6 shadow-xl"
            phx-click=""
          >
            <h2 id="edit-tags-title" class="text-lg font-semibold text-base-content mb-4">
              Edit tags
            </h2>
            <.form
              for={@edit_tags_form}
              id="edit-tags-form"
              phx-submit="save_tags"
              phx-click=""
            >
              <input type="hidden" name="photo_id" value={@edit_tags_photo_id} />
              <.input
                field={@edit_tags_form[:tags]}
                type="text"
                label="Tags (comma-separated)"
                placeholder="e.g. sunset, beach, 2024"
                class="input input-bordered w-full bg-base-200 border-base-300 text-base-content rounded-md"
              />
              <div class="mt-4 flex justify-end gap-2">
                <button
                  type="button"
                  phx-click="close_edit_tags"
                  class="btn btn-ghost rounded-md"
                >
                  Cancel
                </button>
                <button type="submit" class="btn btn-accent rounded-md">
                  Save tags
                </button>
              </div>
            </.form>
          </div>
        </div>
      <% end %>

      <%= if @rename_photo_id do %>
        <div
          id="rename-modal"
          class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4"
          role="dialog"
          aria-modal="true"
          aria-labelledby="rename-title"
        >
          <div
            phx-click="close_rename"
            class="absolute inset-0"
            aria-hidden="true"
          />
          <div
            class="relative z-10 w-full max-w-md rounded-lg bg-base-100 p-6 shadow-xl"
            phx-click=""
          >
            <h2 id="rename-title" class="text-lg font-semibold text-base-content mb-4">
              Rename photo
            </h2>
            <.form
              for={@rename_form}
              id="rename-form"
              phx-submit="rename_photo"
              phx-click=""
            >
              <input type="hidden" name="photo_id" value={@rename_photo_id} />
              <.input
                field={@rename_form[:filename]}
                type="text"
                label="Filename"
                class="input input-bordered w-full bg-base-200 border-base-300 text-base-content rounded-md"
              />
              <div class="mt-4 flex justify-end gap-2">
                <button
                  type="button"
                  phx-click="close_rename"
                  class="btn btn-ghost rounded-md"
                >
                  Cancel
                </button>
                <button type="submit" class="btn btn-accent rounded-md">
                  Save
                </button>
              </div>
            </.form>
          </div>
        </div>
      <% end %>

      <%= if @lightbox_index != nil and @filtered_photos != [] do %>
        <% photo = Enum.at(@filtered_photos, @lightbox_index) %>
        <% total = length(@filtered_photos) %>
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
    </section>
    """
  end
end
