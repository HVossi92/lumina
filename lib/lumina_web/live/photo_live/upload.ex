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
    <section>
      <h1 class="text-3xl font-serif font-bold text-base-content mb-6 text-balance">
        Upload Photos to {@album.name}
      </h1>

      <form id="upload-form" phx-submit="save" phx-change="validate">
        <div
          class="border border-dashed border-base-300 rounded-md p-10 text-center hover:border-accent/50 transition-colors cursor-pointer bg-base-200/40"
          phx-drop-target={@uploads.photos.ref}
        >
          <.icon name="hero-arrow-up-tray" class="mx-auto size-8 text-base-content/20" />
          <p class="text-base-content font-medium text-sm mt-3 mb-1">
            Drop files here or click to browse
          </p>
          <p class="text-xs text-base-content/40">
            PNG, JPG, GIF, WebP up to 10MB (max 10 files)
          </p>
          <.live_file_input upload={@uploads.photos} class="sr-only" />
        </div>

        <%= for entry <- @uploads.photos.entries do %>
          <div class="mt-4 flex items-center gap-3 bg-base-200 rounded-md px-4 py-3 border border-base-300">
            <div class="flex-shrink-0">
              <.live_img_preview entry={entry} class="h-16 w-16 object-cover rounded-md" />
            </div>
            <div class="flex-1 min-w-0">
              <p class="text-sm text-base-content truncate">
                {entry.client_name}
              </p>
              <p class="text-[11px] text-base-content/40 font-mono">
                {Float.round(entry.client_size / 1_000_000, 2)} MB
              </p>
              <div class="mt-2">
                <progress
                  class="progress progress-accent h-1.5 w-full"
                  value={entry.progress}
                  max="100"
                >
                </progress>
              </div>
            </div>
            <button
              type="button"
              phx-click="cancel-upload"
              phx-value-ref={entry.ref}
              class="btn btn-ghost btn-sm btn-square text-error hover:text-error"
              aria-label="Remove"
            >
              <.icon name="hero-x-mark" class="size-5" />
            </button>
          </div>

          <%= for err <- upload_errors(@uploads.photos, entry) do %>
            <p class="mt-2 text-sm text-error">
              {error_to_string(err)}
            </p>
          <% end %>
        <% end %>

        <%= if length(@uploads.photos.entries) > 0 do %>
          <div class="mt-6 flex gap-3">
            <.link
              navigate={~p"/orgs/#{@org.slug}/albums/#{@album.id}"}
              class="btn btn-sm btn-ghost rounded-md"
            >
              Cancel
            </.link>
            <button
              type="submit"
              phx-disable-with="Uploading..."
              class="btn btn-sm btn-accent gap-1.5 rounded-md"
            >
              <.icon name="hero-arrow-up-tray" class="size-4" />
              Upload {length(@uploads.photos.entries)} {if length(@uploads.photos.entries) == 1,
                do: "Photo",
                else: "Photos"}
            </button>
          </div>
        <% end %>
      </form>
    </section>
    """
  end

  defp error_to_string(:too_large), do: "File is too large (max 10MB)"
  defp error_to_string(:not_accepted), do: "File type not accepted"
  defp error_to_string(:too_many_files), do: "Too many files (max 10)"
  defp error_to_string(_), do: "Unknown error"
end
