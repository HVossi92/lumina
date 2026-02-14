defmodule LuminaWeb.AdminController do
  use LuminaWeb, :controller

  def download_backup(conn, %{"filename" => filename}) do
    backup_path = Path.join(System.tmp_dir!(), filename)

    if File.exists?(backup_path) do
      conn
      |> send_download({:file, backup_path}, filename: filename)
      |> halt()
    else
      conn
      |> put_status(404)
      |> text("Backup not found")
    end
  end
end
