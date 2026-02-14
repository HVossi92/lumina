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
    <div class="max-w-2xl mx-auto px-4 py-8">
      <%= if @authenticated do %>
        <h1 class="text-3xl font-bold text-gray-900 mb-6">System Backup</h1>

        <div class="rounded-md bg-yellow-50 p-4 mb-6">
          <div class="flex">
            <div class="flex-shrink-0">
              <svg class="h-5 w-5 text-yellow-400" viewBox="0 0 20 20" fill="currentColor">
                <path
                  fill-rule="evenodd"
                  d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z"
                  clip-rule="evenodd"
                />
              </svg>
            </div>
            <div class="ml-3">
              <h3 class="text-sm font-medium text-yellow-800">
                Warning
              </h3>
              <div class="mt-2 text-sm text-yellow-700">
                <p>
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
          </div>
        </div>

        <button
          phx-click="download_backup"
          class="w-full rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500"
        >
          Download System Backup
        </button>
      <% else %>
        <h1 class="text-3xl font-bold text-gray-900 mb-6">Admin Access Required</h1>

        <.form for={@form} phx-submit="authenticate" class="space-y-4">
          <div>
            <label for="password" class="block text-sm font-medium text-gray-700">
              Admin Password
            </label>
            <input
              type="password"
              name="password"
              id="password"
              class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
              required
              autofocus
            />
          </div>
          <button
            type="submit"
            class="w-full rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500"
          >
            Authenticate
          </button>
        </.form>
      <% end %>
    </div>
    """
  end
end
