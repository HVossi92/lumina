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
    <div class="max-w-2xl mx-auto px-4 py-8">
      <h1 class="text-3xl font-bold text-gray-900 mb-6">
        Share {@album.name}
      </h1>

      <.form for={@form} phx-submit="create_link" class="space-y-6">
        <div>
          <label for="days" class="block text-sm font-medium text-gray-700">
            Link expires in (days)
          </label>
          <input
            type="number"
            name="days"
            id="days"
            value="7"
            min="1"
            max="365"
            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
          />
        </div>

        <div>
          <label for="password" class="block text-sm font-medium text-gray-700">
            Password (optional)
          </label>
          <input
            type="password"
            name="password"
            id="password"
            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
          />
          <p class="mt-2 text-sm text-gray-500">
            Leave empty for public access
          </p>
        </div>

        <div class="flex justify-end gap-3">
          <.link
            navigate={~p"/orgs/#{@org.slug}/albums/#{@album.id}"}
            class="rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50"
          >
            Cancel
          </.link>
          <button
            type="submit"
            class="rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500"
          >
            Generate Share Link
          </button>
        </div>
      </.form>

      <%= if @share_url do %>
        <div class="mt-8 rounded-md bg-green-50 p-4">
          <div class="flex">
            <div class="flex-shrink-0">
              <svg class="h-5 w-5 text-green-400" viewBox="0 0 20 20" fill="currentColor">
                <path
                  fill-rule="evenodd"
                  d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
                  clip-rule="evenodd"
                />
              </svg>
            </div>
            <div class="ml-3 flex-1">
              <h3 class="text-sm font-medium text-green-800">
                Share link created!
              </h3>
              <div class="mt-2">
                <div class="flex gap-2">
                  <input
                    type="text"
                    value={@share_url}
                    readonly
                    id="share-url-input"
                    class="flex-1 rounded-md border-gray-300 bg-white shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                  />
                  <button
                    type="button"
                    phx-click={JS.dispatch("phx:copy", to: "#share-url-input")}
                    class="rounded-md bg-green-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-green-500"
                  >
                    Copy
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
