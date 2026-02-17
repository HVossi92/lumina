defmodule LuminaWeb.OrgLive.Show do
  use LuminaWeb, :live_view

  @impl true
  def mount(%{"org_slug" => slug}, _session, socket) do
    user = socket.assigns.current_user

    case Lumina.Media.Org.by_slug(slug, actor: user) do
      {:ok, org} ->
        org = Ash.load!(org, :memberships, authorize?: false)
        handle_org_access(socket, org, user)

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

  defp handle_org_access(socket, org, user) do
    # Admin who is not a member cannot access org content (albums/photos)
    member? = Enum.any?(org.memberships || [], fn m -> m.user_id == user.id end)

    if user.role == :admin and !member? do
      {:ok,
       socket
       |> put_flash(:error, "You can manage organizations but cannot access their content")
       |> Phoenix.LiveView.redirect(to: ~p"/admin/orgs")}
    else
      cover_photo_query =
        Lumina.Media.Photo
        |> Ash.Query.sort(inserted_at: :asc)
        |> Ash.Query.limit(1)

      org = Ash.load!(org, [albums: [photos: cover_photo_query]], actor: user, tenant: org.id)

      {:ok,
       assign(socket,
         org: org,
         albums: org.albums,
         search_query: "",
         open_menu_album_id: nil,
         page_title: org.name
       )}
    end
  end

  @impl true
  def handle_event("search", %{"q" => q}, socket) do
    {:noreply, assign(socket, search_query: String.trim(q))}
  end

  def handle_event("toggle_album_menu", %{"id" => id}, socket) do
    current = socket.assigns.open_menu_album_id
    open = if current == id, do: nil, else: id
    {:noreply, assign(socket, open_menu_album_id: open)}
  end

  def handle_event("close_album_menu", _params, socket) do
    {:noreply, assign(socket, open_menu_album_id: nil)}
  end

  def handle_event("delete_album", %{"id" => id}, socket) do
    user = socket.assigns.current_user
    org = socket.assigns.org
    album = Ash.get!(Lumina.Media.Album, id, tenant: org.id, actor: user)

    Ash.destroy!(album, actor: user, tenant: org.id)

    cover_photo_query =
      Lumina.Media.Photo
      |> Ash.Query.sort(inserted_at: :asc)
      |> Ash.Query.limit(1)

    org =
      Lumina.Media.Org.by_slug!(org.slug, actor: user)
      |> Ash.load!(:memberships, authorize?: false)
      |> Ash.load!([albums: [photos: cover_photo_query]], actor: user, tenant: org.id)

    {:noreply,
     socket
     |> assign(org: org, albums: org.albums, open_menu_album_id: nil)
     |> put_flash(:info, "Album deleted")}
  end

  @impl true
  def render(assigns) do
    albums = assigns.albums || []
    q = String.downcase(assigns.search_query || "")

    filtered_albums =
      if q == "" do
        albums
      else
        Enum.filter(albums, fn album ->
          String.contains?(String.downcase(album.name || ""), q)
        end)
      end

    album_count = length(filtered_albums)

    assigns =
      assigns
      |> assign(:album_count, album_count)
      |> assign(:filtered_albums, filtered_albums)

    ~H"""
    <section phx-click="close_album_menu">
      <%= if @open_menu_album_id do %>
        <div
          class="fixed inset-0 z-30"
          aria-hidden="true"
          phx-click="close_album_menu"
        />
      <% end %>

      <div class="flex flex-wrap items-end justify-between gap-3 mb-8">
        <div>
          <h1 class="text-3xl font-serif font-bold text-base-content text-balance">
            {@org.name}
          </h1>
          <p class="text-sm text-base-content/40 mt-1">
            {@album_count} {if @album_count == 1, do: "album", else: "albums"}
          </p>
        </div>
        <div class="flex flex-wrap items-center gap-2">
          <form phx-change="search" class="flex-1 min-w-[200px] max-w-xs">
            <input
              type="search"
              name="q"
              value={@search_query}
              placeholder="Search albums..."
              phx-debounce="200"
              class="input input-bordered input-sm bg-base-200/60 border-base-300 text-base-content rounded-md w-full"
            />
          </form>
          <.link
            navigate={~p"/orgs/#{@org.slug}/albums/new"}
            class="btn btn-sm btn-accent gap-1.5 rounded-md"
          >
            <.icon name="hero-plus" class="size-4" /> New Album
          </.link>
        </div>
      </div>

      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
        <%= for album <- @filtered_albums do %>
          <div class="group relative">
            <.link
              navigate={~p"/orgs/#{@org.slug}/albums/#{album.id}"}
              class="block cursor-pointer"
            >
              <figure class="relative aspect-[16/10] overflow-hidden rounded-md bg-base-300">
                <%= if cover_photo = List.first(album.photos || []) do %>
                  <img
                    src={~p"/uploads/thumbnails/#{Path.basename(cover_photo.thumbnail_path)}"}
                    data-original-src={
                      ~p"/uploads/originals/#{Path.basename(cover_photo.original_path)}"
                    }
                    onerror="if(!this.dataset.fallbackAttempted){this.dataset.fallbackAttempted='true';this.src=this.dataset.originalSrc}"
                    alt={album.name}
                    class="h-full w-full object-cover group-hover:scale-[1.03] transition-transform duration-500 ease-out"
                  />
                <% else %>
                  <div class="h-full w-full flex items-center justify-center">
                    <.icon name="hero-photo" class="size-12 text-base-content/30" />
                  </div>
                <% end %>
                <div class="absolute inset-0 bg-gradient-to-t from-base-content/60 via-base-content/10 to-transparent" />
                <div class="absolute bottom-3 left-3 right-3 flex items-end justify-between">
                  <div>
                    <h3 class="text-base-100 font-serif font-semibold text-base">{album.name}</h3>
                    <p class="text-base-100/70 text-xs font-mono">
                      {length(album.photos || [])} photos
                    </p>
                  </div>
                </div>
              </figure>
            </.link>
            <div class="absolute top-2 right-2 z-10">
              <button
                type="button"
                phx-click="toggle_album_menu"
                phx-value-id={album.id}
                class="btn btn-ghost btn-sm btn-square rounded-md bg-base-100/80 hover:bg-base-100 text-base-content"
                aria-label="Album menu"
              >
                <.icon name="hero-ellipsis-vertical" class="size-5" />
              </button>
              <%= if @open_menu_album_id == album.id do %>
                <div class="absolute right-0 top-full mt-1 py-1 min-w-[120px] rounded-md bg-base-100 border border-base-300 shadow-lg z-40">
                  <button
                    type="button"
                    phx-click="delete_album"
                    phx-value-id={album.id}
                    data-confirm="Delete this album and all its photos? This cannot be undone."
                    class="w-full text-left px-3 py-2 text-sm text-error hover:bg-base-200 rounded flex items-center gap-2"
                  >
                    <.icon name="hero-trash" class="size-4" /> Delete
                  </button>
                </div>
              <% end %>
            </div>
          </div>
        <% end %>
      </div>

      <%= if @filtered_albums == [] do %>
        <div class="flex flex-col items-center justify-center py-16 text-center">
          <div class="bg-base-300 rounded-full p-4 mb-4">
            <.icon name="hero-photo" class="size-8 text-base-content/30" />
          </div>
          <h3 class="text-lg font-serif font-semibold text-base-content mb-1">
            No albums yet
          </h3>
          <p class="text-sm text-base-content/40 mb-4 max-w-xs">
            Create your first album to start organizing your photos.
          </p>
          <.link
            navigate={~p"/orgs/#{@org.slug}/albums/new"}
            class="btn btn-accent btn-sm gap-1.5 rounded-md"
          >
            <.icon name="hero-plus" class="size-4" /> Create Album
          </.link>
        </div>
      <% end %>
    </section>
    """
  end
end
