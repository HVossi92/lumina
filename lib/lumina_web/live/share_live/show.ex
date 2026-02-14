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
    <div class="min-h-screen bg-base-100">
      <%!-- Minimal Lumina header for public share --%>
      <header class="border-b border-base-300 px-4 py-3">
        <a href="/" class="flex w-fit items-center gap-2.5">
          <.icon name="hero-photo" class="size-5 text-accent" />
          <span class="font-serif font-bold text-base-content tracking-tight">Lumina</span>
        </a>
      </header>

      <div class="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <%= if @error do %>
          <div class="flex flex-col items-center justify-center py-16 text-center">
            <div class="bg-error/10 rounded-full p-4 mb-4">
              <.icon name="hero-exclamation-triangle" class="size-8 text-error" />
            </div>
            <h1 class="text-2xl font-serif font-bold text-base-content">{@error}</h1>
          </div>
        <% else %>
          <%= if @password_required and not @authenticated do %>
            <div class="max-w-md mx-auto">
              <div class="text-center mb-6">
                <div class="bg-base-300 rounded-full p-4 inline-flex mb-4">
                  <.icon name="hero-lock-closed" class="size-8 text-base-content/30" />
                </div>
                <h1 class="text-2xl font-serif font-bold text-base-content">Password Required</h1>
              </div>

              <form phx-submit="check_password" id="share-password-form" class="space-y-4">
                <div class="form-control">
                  <label for="password" class="sr-only">Password</label>
                  <input
                    type="password"
                    name="password"
                    id="password"
                    placeholder="Enter password"
                    class="input input-bordered input-sm bg-base-200/60 border-base-300 text-base-content rounded-md w-full"
                    required
                    autofocus
                  />
                </div>
                <button type="submit" class="btn btn-accent w-full rounded-md">
                  Access Album
                </button>
              </form>
            </div>
          <% else %>
            <div class="mb-8">
              <h1 class="text-3xl font-serif font-bold text-base-content text-balance">
                {@album.name}
              </h1>
              <%= if @album.description do %>
                <p class="mt-2 text-base-content/60">{@album.description}</p>
              <% end %>
            </div>

            <div class="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4">
              <%= for photo <- @photos do %>
                <div class="aspect-square overflow-hidden rounded-md bg-base-300">
                  <img
                    src={~p"/uploads/thumbnails/#{Path.basename(photo.thumbnail_path)}"}
                    data-original-src={~p"/uploads/originals/#{Path.basename(photo.original_path)}"}
                    onerror="if(!this.dataset.fallbackAttempted){this.dataset.fallbackAttempted='true';this.src=this.dataset.originalSrc}"
                    alt={photo.filename}
                    class="h-full w-full object-cover"
                  />
                </div>
              <% end %>
            </div>

            <%= if @photos == [] do %>
              <div class="flex flex-col items-center justify-center py-16 text-center">
                <div class="bg-base-300 rounded-full p-4 mb-4">
                  <.icon name="hero-photo" class="size-8 text-base-content/30" />
                </div>
                <p class="text-sm text-base-content/40">This album is empty</p>
              </div>
            <% end %>
          <% end %>
        <% end %>
      </div>
    </div>
    """
  end
end
