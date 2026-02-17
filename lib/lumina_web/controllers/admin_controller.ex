defmodule LuminaWeb.AdminController do
  use LuminaWeb, :controller

  @backup_filename_pattern ~r/\Alumina_backup_\d{8}_\d{6}\.tar\.gz\z/

  def download_backup(conn, %{"filename" => filename}) do
    if filename =~ @backup_filename_pattern do
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
    else
      conn
      |> put_status(400)
      |> text("Invalid filename")
    end
  end
end
