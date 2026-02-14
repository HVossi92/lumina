defmodule LuminaWeb.AlbumLive.Share do
  use LuminaWeb, :live_view

  @impl true
  def mount(%{"org_slug" => slug, "album_id" => album_id}, _session, socket) do
    user = socket.assigns.current_user

    org = Lumina.Media.Org.by_slug!(slug, actor: user)
    album = Ash.get!(Lumina.Media.Album, album_id, tenant: org.id, actor: user)

    {:ok,
     assign(socket,
       org: org,
       album: album,
       share_url: nil,
       form: to_form(%{}, as: "share"),
       page_title: "Share Album"
     )}
  end

  @impl true
  def handle_event("create_link", params, socket) do
    user = socket.assigns.current_user
    album = socket.assigns.album

    days = String.to_integer(params["days"] || "7")
    expires_at = DateTime.utc_now() |> DateTime.add(days, :day)

    password_hash =
      if params["password"] != "" do
        Bcrypt.hash_pwd_salt(params["password"])
      else
        nil
      end

    {:ok, share_link} =
      Lumina.Media.ShareLink
      |> Ash.Changeset.for_create(:create, %{
        expires_at: expires_at,
        password_hash: password_hash,
        album_id: album.id,
        created_by_id: user.id
      })
      |> Ash.create(actor: user, tenant: socket.assigns.org.id)

    share_url = url(~p"/share/#{share_link.token}")

    {:noreply,
     socket
     |> assign(share_url: share_url)
     |> put_flash(:info, "Share link created successfully")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section>
      <h1 class="text-3xl font-serif font-bold text-base-content mb-6 text-balance">
        Share {@album.name}
      </h1>

      <.form for={@form} phx-submit="create_link" id="share-form" class="space-y-6">
        <div class="form-control">
          <label for="days" class="label">
            <span class="label-text text-base-content text-sm">Link expires in (days)</span>
          </label>
          <input
            type="number"
            name="days"
            id="days"
            value="7"
            min="1"
            max="365"
            class="input input-bordered input-sm bg-base-200/60 border-base-300 text-base-content rounded-md w-full"
          />
        </div>

        <div class="form-control">
          <label for="password" class="label">
            <span class="label-text text-base-content text-sm">Password (optional)</span>
          </label>
          <input
            type="password"
            name="password"
            id="password"
            class="input input-bordered input-sm bg-base-200/60 border-base-300 text-base-content rounded-md w-full"
          />
          <p class="mt-2 text-sm text-base-content/40">
            Leave empty for public access
          </p>
        </div>

        <div class="flex justify-end gap-3">
          <.link
            navigate={~p"/orgs/#{@org.slug}/albums/#{@album.id}"}
            class="btn btn-sm btn-ghost rounded-md"
          >
            Cancel
          </.link>
          <button type="submit" class="btn btn-sm btn-accent rounded-md">
            Generate Share Link
          </button>
        </div>
      </.form>

      <%= if @share_url do %>
        <div class="mt-8 alert alert-success rounded-md text-sm">
          <.icon name="hero-check-circle" class="size-5 shrink-0" />
          <div class="flex-1">
            <h3 class="font-medium">Share link created!</h3>
            <div class="mt-2 flex gap-2">
              <input
                type="text"
                value={@share_url}
                readonly
                id="share-url-input"
                class="input input-bordered input-sm flex-1 bg-base-200/60 border-base-300 text-base-content rounded-md font-mono text-xs"
              />
              <button
                type="button"
                phx-click={JS.dispatch("phx:copy", to: "#share-url-input")}
                class="btn btn-sm btn-success rounded-md"
              >
                Copy
              </button>
            </div>
          </div>
        </div>
      <% end %>
    </section>
    """
  end
end
