defmodule LuminaWeb.AdminLive.Backup do
  use LuminaWeb, :live_view

  @backup_password System.get_env("LUMINA_BACKUP_PASSWORD", "change-me-in-production")

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       authenticated: false,
       form: to_form(%{}, as: "auth"),
       page_title: "Admin Backup"
     )}
  end

  @impl true
  def handle_event("authenticate", %{"password" => password}, socket) do
    if password == @backup_password do
      {:noreply, assign(socket, authenticated: true)}
    else
      {:noreply,
       socket
       |> put_flash(:error, "Invalid password")
       |> assign(authenticated: false)}
    end
  end

  @impl true
  def handle_event("download_backup", _params, socket) do
    timestamp = DateTime.utc_now() |> Calendar.strftime("%Y%m%d_%H%M%S")
    backup_filename = "lumina_backup_#{timestamp}.tar.gz"
    backup_path = Path.join(System.tmp_dir!(), backup_filename)

    # Create tar.gz of database + uploads
    {_output, 0} =
      System.cmd(
        "tar",
        [
          "-czf",
          backup_path,
          "-C",
          File.cwd!(),
          "lumina_dev.db",
          "lumina_dev.db-shm",
          "lumina_dev.db-wal",
          "priv/static/uploads"
        ],
        stderr_to_stdout: true
      )

    # Trigger download via JavaScript
    {:noreply,
     push_event(socket, "trigger_download", %{
       url: ~p"/admin/backup/download/#{backup_filename}",
       filename: backup_filename
     })}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section>
      <%= if @authenticated do %>
        <h1 class="text-3xl font-serif font-bold text-base-content mb-6 text-balance">
          System Backup
        </h1>

        <div class="alert alert-warning rounded-md text-sm mb-6">
          <.icon name="hero-exclamation-triangle" class="size-5 shrink-0" />
          <div>
            <h3 class="font-medium">Warning</h3>
            <p class="mt-1">
              This will download a complete backup including:
            </p>
            <ul class="list-disc list-inside mt-2 space-y-1">
              <li>SQLite database</li>
              <li>All uploaded photos (originals + thumbnails)</li>
            </ul>
            <p class="mt-2">
              The backup may be large depending on the number of photos stored.
            </p>
          </div>
        </div>

        <button
          phx-click="download_backup"
          class="btn btn-accent w-full rounded-md"
        >
          Download System Backup
        </button>
      <% else %>
        <h1 class="text-3xl font-serif font-bold text-base-content mb-6 text-balance">
          Admin Access Required
        </h1>

        <.form for={@form} id="admin-backup-auth-form" phx-submit="authenticate" class="space-y-4">
          <div class="form-control">
            <label for="password" class="label">
              <span class="label-text text-base-content text-sm">Admin Password</span>
            </label>
            <input
              type="password"
              name="password"
              id="password"
              class="input input-bordered input-sm bg-base-200/60 border-base-300 text-base-content rounded-md w-full"
              required
              autofocus
            />
          </div>
          <button type="submit" class="btn btn-accent w-full rounded-md">
            Authenticate
          </button>
        </.form>
      <% end %>
    </section>
    """
  end
end
