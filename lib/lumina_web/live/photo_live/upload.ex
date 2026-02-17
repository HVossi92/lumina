defmodule LuminaWeb.PhotoLive.Upload do
  use LuminaWeb, :live_view

  alias Lumina.Media.{Org, Photo, Thumbnail}
  alias Lumina.Jobs.ProcessUpload

  @storage_limit_message "Organization storage limit (4 GB) would be exceeded"

  @impl true
  def mount(%{"org_slug" => slug, "album_id" => album_id}, _session, socket) do
    user = socket.assigns.current_user

    case Lumina.Media.Org.by_slug(slug, actor: user) do
      {:ok, org} ->
        case Ash.get(Lumina.Media.Album, album_id, tenant: org.id, actor: user) do
          {:ok, album} ->
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

  @impl true
  def handle_event("validate", _params, socket) do
    require Logger
    Logger.info("[Upload] validate event received")

    Logger.info(
      "[Upload] Current upload entries: #{length(socket.assigns.uploads.photos.entries)}"
    )

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
    org = socket.assigns.org

    current_used = Lumina.Media.Storage.used_bytes(org.id)
    limit = Org.storage_limit_bytes()

    batch_total =
      socket.assigns.uploads.photos.entries
      |> Enum.map(& &1.client_size)
      |> Enum.sum()

    if current_used + batch_total > limit do
      {:noreply,
       socket
       |> put_flash(:error, @storage_limit_message)}
    else
      save_uploaded_entries(socket, user, album, org)
    end
  end

  defp save_uploaded_entries(socket, user, album, org) do
    uploaded_files =
      consume_uploaded_entries(socket, :photos, fn %{path: path}, entry ->
        photo_id = Ash.UUID.generate()
        filename = entry.client_name

        original_path = Thumbnail.original_path(photo_id, filename)
        thumbnail_path = Thumbnail.thumbnail_path(photo_id, filename)

        try do
          # Ensure directories exist
          File.mkdir_p(Path.dirname(original_path))
          File.mkdir_p(Path.dirname(thumbnail_path))

          # Copy uploaded file
          case File.cp(path, original_path) do
            :ok ->
              # Get file size safely
              file_size =
                case File.stat(path) do
                  {:ok, stat} -> stat.size
                  {:error, _} -> 0
                end

              # Create photo record
              case Photo
                   |> Ash.Changeset.for_create(:create, %{
                     filename: filename,
                     original_path: original_path,
                     thumbnail_path: thumbnail_path,
                     file_size: file_size,
                     content_type: entry.client_type,
                     album_id: album.id,
                     uploaded_by_id: user.id
                   })
                   |> Ash.create(actor: user, tenant: org.id) do
                {:ok, photo} ->
                  # Queue thumbnail generation
                  case ProcessUpload.new(%{photo_id: photo.id}) |> Oban.insert() do
                    {:ok, _job} ->
                      {:ok, photo}

                    {:error, reason} ->
                      # Log error but continue - thumbnail will be generated later if needed
                      require Logger

                      Logger.warning(
                        "Failed to queue thumbnail job for photo #{photo.id}: #{inspect(reason)}"
                      )

                      {:ok, photo}
                  end

                {:error, error} ->
                  # Clean up copied file if photo creation failed
                  File.rm(original_path)
                  throw({:error, "Failed to create photo record: #{Exception.message(error)}"})
              end

            {:error, reason} ->
              throw({:error, "Failed to save file: #{inspect(reason)}"})
          end
        catch
          {:error, message} ->
            throw({:error, message})
        end
      end)

    case uploaded_files do
      [] ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to upload photos. Please try again.")}

      files when is_list(files) ->
        success_count = Enum.count(files, &match?({:ok, _}, &1))
        error_count = length(files) - success_count

        message =
          cond do
            error_count == 0 ->
              "#{success_count} photos uploaded successfully!"

            success_count == 0 ->
              "Failed to upload photos. Please try again."

            true ->
              "#{success_count} photos uploaded successfully. #{error_count} failed."
          end

        flash_kind = if error_count == 0, do: :info, else: :error

        {:noreply,
         socket
         |> put_flash(flash_kind, message)
         |> push_navigate(to: ~p"/orgs/#{org.slug}/albums/#{album.id}")}
    end
  end

  @impl true
  def render(assigns) do
    require Logger
    Logger.info("[Upload] Rendering upload page")
    Logger.info("[Upload] Upload ref: #{inspect(assigns.uploads.photos.ref)}")
    Logger.info("[Upload] Upload entries count: #{length(assigns.uploads.photos.entries)}")

    ~H"""
    <section>
      <h1 class="text-3xl font-serif font-bold text-base-content mb-6 text-balance">
        Upload Photos to {@album.name}
      </h1>

      <form id="upload-form" phx-submit="save" phx-change="validate">
        <label
          id="upload-dropzone-label"
          for="upload-photos-input"
          class="block border border-dashed border-base-300 rounded-md p-10 text-center hover:border-accent/50 transition-colors cursor-pointer bg-base-200/40"
          phx-drop-target={@uploads.photos.ref}
          phx-hook=".UploadDebug"
        >
          <.icon name="hero-arrow-up-tray" class="mx-auto size-8 text-base-content/20" />
          <p class="text-base-content font-medium text-sm mt-3 mb-1">
            Drop files here or click to browse
          </p>
          <p class="text-xs text-base-content/40">
            PNG, JPG, GIF, WebP up to 10MB (max 10 files)
          </p>
          <.live_file_input id="upload-photos-input" upload={@uploads.photos} class="sr-only" />
        </label>

        <script :type={Phoenix.LiveView.ColocatedHook} name=".UploadDebug">
          export default {
            mounted() {
              console.log("[UploadDebug] Hook mounted");
              console.log("[UploadDebug] Label element:", this.el);
              console.log("[UploadDebug] Label for attribute:", this.el.getAttribute("for"));

              // Search for file input by ID
              const fileInputById = document.getElementById("upload-photos-input");
              console.log("[UploadDebug] File input by ID 'upload-photos-input':", fileInputById);

              // Search for ALL file inputs in the form
              const form = document.getElementById("upload-form");
              console.log("[UploadDebug] Form found:", form);

              if (form) {
                const allFileInputs = form.querySelectorAll('input[type="file"]');
                console.log("[UploadDebug] All file inputs in form:", allFileInputs);
                console.log("[UploadDebug] File input count:", allFileInputs.length);

                allFileInputs.forEach((input, index) => {
                  console.log(`[UploadDebug] File input ${index}:`, input);
                  console.log(`[UploadDebug] File input ${index} id:`, input.id);
                  console.log(`[UploadDebug] File input ${index} name:`, input.name);
                  console.log(`[UploadDebug] File input ${index} classes:`, input.className);
                  console.log(`[UploadDebug] File input ${index} parent:`, input.parentElement);
                  console.log(`[UploadDebug] File input ${index} is inside label:`, this.el.contains(input));
                });

                // Also check inside the label
                const inputsInLabel = this.el.querySelectorAll('input[type="file"]');
                console.log("[UploadDebug] File inputs inside label:", inputsInLabel);
                console.log("[UploadDebug] File inputs inside label count:", inputsInLabel.length);
              }

              // Check if label is correctly associated
              const labelFor = this.el.getAttribute("for");
              console.log("[UploadDebug] Label 'for' value:", labelFor);

              // Add click listener to label
              this.el.addEventListener("click", (e) => {
                console.log("[UploadDebug] Label clicked!", e);
                console.log("[UploadDebug] Click target:", e.target);
                console.log("[UploadDebug] Click currentTarget:", e.currentTarget);

                // Try to find file input again on click
                const inputById = document.getElementById("upload-photos-input");
                console.log("[UploadDebug] File input by ID on click:", inputById);

                // Try to find any file input in the form
                const form = document.getElementById("upload-form");
                if (form) {
                  const allFileInputs = form.querySelectorAll('input[type="file"]');
                  console.log("[UploadDebug] All file inputs on click:", allFileInputs);

                  if (allFileInputs.length > 0) {
                    const firstInput = allFileInputs[0];
                    console.log("[UploadDebug] Using first file input:", firstInput);
                    console.log("[UploadDebug] First file input id:", firstInput.id);
                    console.log("[UploadDebug] Attempting to trigger file input click");
                    firstInput.click();
                    console.log("[UploadDebug] File input click triggered");
                  } else {
                    console.error("[UploadDebug] No file inputs found in form!");
                  }
                } else {
                  console.error("[UploadDebug] Form not found!");
                }
              });

              // Listen for file input changes on the form
              if (form) {
                form.addEventListener("change", (e) => {
                  if (e.target.type === "file") {
                    console.log("[UploadDebug] File input changed!", e);
                    console.log("[UploadDebug] Selected files:", e.target.files);
                  }
                });
              }
            }
          }
        </script>

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
