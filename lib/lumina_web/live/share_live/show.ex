defmodule LuminaWeb.ShareLive.Show do
  use LuminaWeb, :live_view

  alias Lumina.Media.ShareLink

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    case ShareLink.by_token(token) do
      {:ok, share_link} ->
        if DateTime.compare(share_link.expires_at, DateTime.utc_now()) == :lt do
          {:ok,
           assign(socket,
             error: "This link has expired",
             share_link: nil,
             page_title: "Expired Link"
           )}
        else
          # Load album with photos using Repo for multi-tenancy bypass in public context
          album = Lumina.Repo.get!(Lumina.Media.Album, share_link.album_id)
          album = Ash.load!(album, [:photos], authorize?: false, tenant: share_link.org_id)
          share_link = %{share_link | album: album}

          # Increment view count
          {:ok, _} =
            share_link
            |> Ash.Changeset.for_update(:increment_view_count)
            |> Ash.update()

          {:ok,
           assign(socket,
             share_link: share_link,
             album: share_link.album,
             photos: share_link.album.photos,
             password_required: !is_nil(share_link.password_hash),
             authenticated: is_nil(share_link.password_hash),
             error: nil,
             page_title: share_link.album.name
           )}
        end

      {:error, _} ->
        {:ok,
         assign(socket, error: "Invalid share link", share_link: nil, page_title: "Invalid Link")}
    end
  end

  @impl true
  def handle_event("check_password", %{"password" => password}, socket) do
    share_link = socket.assigns.share_link

    if Bcrypt.verify_pass(password, share_link.password_hash) do
      {:noreply, assign(socket, authenticated: true)}
    else
      {:noreply, put_flash(socket, :error, "Invalid password")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto px-4 py-8">
      <%= if @error do %>
        <div class="text-center py-12">
          <svg
            class="mx-auto h-12 w-12 text-red-400"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
            />
          </svg>
          <h1 class="mt-4 text-2xl font-bold text-gray-900">{@error}</h1>
        </div>
      <% else %>
        <%= if @password_required and not @authenticated do %>
          <div class="max-w-md mx-auto">
            <div class="text-center mb-6">
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
                  d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
                />
              </svg>
              <h1 class="mt-4 text-2xl font-bold text-gray-900">Password Required</h1>
            </div>

            <form phx-submit="check_password" class="space-y-4">
              <div>
                <label for="password" class="sr-only">Password</label>
                <input
                  type="password"
                  name="password"
                  id="password"
                  placeholder="Enter password"
                  class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                  required
                  autofocus
                />
              </div>
              <button
                type="submit"
                class="w-full rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500"
              >
                Access Album
              </button>
            </form>
          </div>
        <% else %>
          <div class="mb-8">
            <h1 class="text-3xl font-bold text-gray-900">{@album.name}</h1>
            <%= if @album.description do %>
              <p class="mt-2 text-gray-600">{@album.description}</p>
            <% end %>
          </div>

          <div class="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4">
            <%= for photo <- @photos do %>
              <div class="aspect-square">
                <img
                  src={~p"/uploads/thumbnails/#{Path.basename(photo.thumbnail_path)}"}
                  data-original-src={~p"/uploads/originals/#{Path.basename(photo.original_path)}"}
                  onerror="if(!this.dataset.fallbackAttempted){this.dataset.fallbackAttempted='true';this.src=this.dataset.originalSrc}"
                  alt={photo.filename}
                  class="h-full w-full object-cover rounded-lg"
                />
              </div>
            <% end %>
          </div>

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
              <p class="mt-2 text-sm text-gray-500">This album is empty</p>
            </div>
          <% end %>
        <% end %>
      <% end %>
    </div>
    """
  end
end
