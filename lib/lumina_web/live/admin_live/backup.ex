defmodule LuminaWeb.AdminLive.Backup do
  use LuminaWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    if user.role != :admin do
      {:ok,
       socket
       |> put_flash(:error, "Only administrators can access this page")
       |> Phoenix.LiveView.redirect(to: ~p"/")}
    else
      {:ok,
       assign(socket,
         page_title: "Admin Backup"
       )}
    end
  end

  @impl true
  def handle_event("download_backup", _params, socket) do
    timestamp = DateTime.utc_now() |> Calendar.strftime("%Y%m%d_%H%M%S")
    backup_filename = "lumina_backup_#{timestamp}.tar.gz"
    backup_path = Path.join(System.tmp_dir!(), backup_filename)

    database_path = Lumina.Repo.config()[:database]
    db_dir = Path.dirname(database_path)
    db_base = Path.basename(database_path)

    db_files =
      [db_base] ++
        if(File.exists?(database_path <> "-shm"), do: [db_base <> "-shm"], else: []) ++
        if File.exists?(database_path <> "-wal"), do: [db_base <> "-wal"], else: []

    tar_args =
      ["-czf", backup_path, "-C", db_dir | db_files] ++
        ["-C", File.cwd!(), "priv/static/uploads"]

    {_output, 0} = System.cmd("tar", tar_args, stderr_to_stdout: true)

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
    <section id="admin-backup-section" phx-hook=".BackupDownload">
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
        id="admin-backup-download-btn"
        class="btn btn-accent w-full rounded-md group"
      >
        <span class="group-[.phx-loading]:hidden">
          Download System Backup
        </span>
        <span class="hidden group-[.phx-loading]:inline-flex items-center justify-center gap-2">
          <.icon name="hero-arrow-path" class="size-5 animate-spin shrink-0" /> Creating backup...
        </span>
      </button>
    </section>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".BackupDownload">
      export default {
        mounted() {
          this.handleEvent("trigger_download", ({ url, filename }) => {
            const a = document.createElement("a");
            a.href = url;
            a.download = filename || "";
            a.style.display = "none";
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
          });
        }
      }
    </script>
    """
  end
end
