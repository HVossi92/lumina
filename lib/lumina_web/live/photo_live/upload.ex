defmodule LuminaWeb.PhotoLive.Upload do
  use LuminaWeb, :live_view

  alias Lumina.Media.{Photo, Thumbnail}
  alias Lumina.Jobs.ProcessUpload

  @impl true
  def mount(%{"org_slug" => slug, "album_id" => album_id}, _session, socket) do
    user = socket.assigns.current_user

    org = Lumina.Media.Org.by_slug!(slug, actor: user)
    album = Ash.get!(Lumina.Media.Album, album_id, tenant: org.id, actor: user)

    socket =
      socket
      |> assign(org: org, album: album, page_title: "Upload Photos")
      |> allow_upload(:photos,
        accept: ~w(.jpg .jpeg .png .gif .webp),
        max_entries: 10,
        max_file_size: 10_000_000,
        auto_upload: true
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :photos, ref)}
  end

  @impl true
  def handle_event("save", _params, socket) do
    user = socket.assigns.current_user
    album = socket.assigns.album

    uploaded_files =
      consume_uploaded_entries(socket, :photos, fn %{path: path}, entry ->
        photo_id = Ash.UUID.generate()
        filename = entry.client_name

        original_path = Thumbnail.original_path(photo_id, filename)
        thumbnail_path = Thumbnail.thumbnail_path(photo_id, filename)

        # Ensure directories exist
        File.mkdir_p!(Path.dirname(original_path))
        File.mkdir_p!(Path.dirname(thumbnail_path))

        # Copy uploaded file
        File.cp!(path, original_path)

        # Create photo record
        {:ok, photo} =
          Photo
          |> Ash.Changeset.for_create(:create, %{
            filename: filename,
            original_path: original_path,
            thumbnail_path: thumbnail_path,
            file_size: File.stat!(path).size,
            content_type: entry.client_type,
            album_id: album.id,
            uploaded_by_id: user.id
          })
          |> Ash.create(actor: user, tenant: socket.assigns.org.id)

        # Queue thumbnail generation
        %{photo_id: photo.id}
        |> ProcessUpload.new()
        |> Oban.insert()

        {:ok, photo}
      end)

    {:noreply,
     socket
     |> put_flash(:info, "#{length(uploaded_files)} photos uploaded successfully!")
     |> push_navigate(to: ~p"/orgs/#{socket.assigns.org.slug}/albums/#{album.id}")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto px-4 py-8">
      <h1 class="text-3xl font-bold text-gray-900 mb-6">
        Upload Photos to {@album.name}
      </h1>

      <form id="upload-form" phx-submit="save" phx-change="validate">
        <div class="border-2 border-dashed border-gray-300 rounded-lg p-12 text-center hover:border-gray-400 transition">
          <svg
            class="mx-auto h-12 w-12 text-gray-400"
            stroke="currentColor"
            fill="none"
            viewBox="0 0 48 48"
          >
            <path
              d="M28 8H12a4 4 0 00-4 4v20m32-12v8m0 0v8a4 4 0 01-4 4H12a4 4 0 01-4-4v-4m32-4l-3.172-3.172a4 4 0 00-5.656 0L28 28M8 32l9.172-9.172a4 4 0 015.656 0L28 28m0 0l4 4m4-24h8m-4-4v8m-12 4h.02"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
            />
          </svg>

          <div class="mt-4">
            <label for={@uploads.photos.ref} class="cursor-pointer">
              <span class="mt-2 block text-sm font-medium text-indigo-600 hover:text-indigo-500">
                Click to upload
              </span>
              <.live_file_input upload={@uploads.photos} class="sr-only" />
            </label>
            <p class="mt-1 text-xs text-gray-500">
              or drag and drop
            </p>
          </div>

          <p class="mt-2 text-xs text-gray-500">
            PNG, JPG, GIF, WebP up to 10MB (max 10 files)
          </p>
        </div>

        <%= for entry <- @uploads.photos.entries do %>
          <div class="mt-4 flex items-center gap-4 p-4 border border-gray-200 rounded-lg">
            <div class="flex-shrink-0">
              <.live_img_preview entry={entry} class="h-20 w-20 object-cover rounded" />
            </div>
            <div class="flex-1 min-w-0">
              <p class="text-sm font-medium text-gray-900 truncate">
                {entry.client_name}
              </p>
              <p class="text-sm text-gray-500">
                {Float.round(entry.client_size / 1_000_000, 2)} MB
              </p>
              <div class="mt-2">
                <div class="relative pt-1">
                  <div class="overflow-hidden h-2 text-xs flex rounded bg-gray-200">
                    <div
                      style={"width: #{entry.progress}%"}
                      class="shadow-none flex flex-col text-center whitespace-nowrap text-white justify-center bg-indigo-500 transition-all duration-300"
                    >
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <button
              type="button"
              phx-click="cancel-upload"
              phx-value-ref={entry.ref}
              class="flex-shrink-0 text-red-600 hover:text-red-800"
            >
              <svg class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                <path
                  fill-rule="evenodd"
                  d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z"
                  clip-rule="evenodd"
                />
              </svg>
            </button>
          </div>

          <%= for err <- upload_errors(@uploads.photos, entry) do %>
            <p class="mt-2 text-sm text-red-600">
              {error_to_string(err)}
            </p>
          <% end %>
        <% end %>

        <%= if length(@uploads.photos.entries) > 0 do %>
          <div class="mt-6 flex justify-end gap-3">
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
              Upload {length(@uploads.photos.entries)} {if length(@uploads.photos.entries) ==
                                                             1,
                                                           do: "Photo",
                                                           else: "Photos"}
            </button>
          </div>
        <% end %>
      </form>
    </div>
    """
  end

  defp error_to_string(:too_large), do: "File is too large (max 10MB)"
  defp error_to_string(:not_accepted), do: "File type not accepted"
  defp error_to_string(:too_many_files), do: "Too many files (max 10)"
  defp error_to_string(_), do: "Unknown error"
end
