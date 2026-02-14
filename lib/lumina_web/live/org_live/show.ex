defmodule LuminaWeb.OrgLive.Show do
  use LuminaWeb, :live_view

  @impl true
  def mount(%{"org_slug" => slug}, _session, socket) do
    user = socket.assigns.current_user

    org = Lumina.Media.Org.by_slug!(slug, actor: user)
    org = Ash.load!(org, :memberships, authorize?: false)

    # Admin who is not a member cannot access org content (albums/photos)
    member? = Enum.any?(org.memberships || [], fn m -> m.user_id == user.id end)

    if user.role == :admin and !member? do
      {:halt,
       socket
       |> put_flash(:error, "You can manage organizations but cannot access their content")
       |> Phoenix.LiveView.redirect(to: ~p"/admin/orgs")}
    else
      cover_photo_query =
        Lumina.Media.Photo
        |> Ash.Query.sort(inserted_at: :asc)
        |> Ash.Query.limit(1)

      org = Ash.load!(org, [albums: [photos: cover_photo_query]], actor: user, tenant: org.id)

      {:ok, assign(socket, org: org, albums: org.albums, page_title: org.name)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto px-4 py-8">
      <div class="sm:flex sm:items-center">
        <div class="sm:flex-auto">
          <h1 class="text-3xl font-bold text-gray-900">{@org.name}</h1>
        </div>
        <div class="mt-4 sm:ml-16 sm:mt-0 flex gap-3">
          <.link
            navigate={~p"/orgs/#{@org.slug}/albums/new"}
            class="inline-flex items-center rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500"
          >
            New Album
          </.link>
        </div>
      </div>

      <div class="mt-8 grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
        <%= for album <- @albums do %>
          <.link
            navigate={~p"/orgs/#{@org.slug}/albums/#{album.id}"}
            class="group relative flex flex-col rounded-lg border border-gray-300 bg-white overflow-hidden shadow-sm hover:shadow-md transition"
          >
            <div class="aspect-square bg-gray-100 flex items-center justify-center overflow-hidden">
              <%= if cover_photo = List.first(album.photos || []) do %>
                <img
                  src={~p"/uploads/thumbnails/#{Path.basename(cover_photo.thumbnail_path)}"}
                  data-original-src={
                    ~p"/uploads/originals/#{Path.basename(cover_photo.original_path)}"
                  }
                  onerror="if(!this.dataset.fallbackAttempted){this.dataset.fallbackAttempted='true';this.src=this.dataset.originalSrc}"
                  alt={album.name}
                  class="h-full w-full object-cover"
                />
              <% else %>
                <svg
                  class="h-12 w-12 text-gray-400"
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
              <% end %>
            </div>
            <div class="px-6 py-5">
              <h3 class="text-lg font-semibold text-gray-900">{album.name}</h3>
              <%= if album.description do %>
                <p class="mt-2 text-sm text-gray-600 line-clamp-2">{album.description}</p>
              <% end %>
            </div>
          </.link>
        <% end %>
      </div>

      <%= if @albums == [] do %>
        <div class="mt-8 text-center">
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
          <h3 class="mt-2 text-sm font-medium text-gray-900">No albums</h3>
          <p class="mt-1 text-sm text-gray-500">Get started by creating a new album.</p>
          <div class="mt-6">
            <.link
              navigate={~p"/orgs/#{@org.slug}/albums/new"}
              class="inline-flex items-center rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500"
            >
              New Album
            </.link>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
