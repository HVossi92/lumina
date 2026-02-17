defmodule LuminaWeb.AdminControllerTest do
  use LuminaWeb.ConnCase

  import Lumina.Fixtures

  describe "GET /admin/backup/download/:filename" do
    test "redirects to sign-in when not logged in", %{conn: conn} do
      conn = get(conn, ~p"/admin/backup/download/lumina_backup_20250101_120000.tar.gz")

      assert redirected_to(conn) =~ "/sign-in"
    end

    test "redirects to / with error when logged in as non-admin", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      conn = get(conn, ~p"/admin/backup/download/lumina_backup_20250101_120000.tar.gz")

      assert redirected_to(conn) == ~p"/"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "Only administrators can access this page"
    end

    test "returns 404 when admin and file does not exist", %{conn: conn} do
      admin = admin_fixture()
      conn = log_in_user(conn, admin)
      conn = get(conn, ~p"/admin/backup/download/lumina_backup_20250101_120000.tar.gz")

      assert conn.status == 404
      assert conn.resp_body =~ "Backup not found"
    end

    test "downloads backup file when admin and file exists", %{conn: conn} do
      admin = admin_fixture()
      conn = log_in_user(conn, admin)

      # Create a temporary backup file
      filename = "lumina_backup_20250101_120000.tar.gz"
      backup_path = Path.join(System.tmp_dir!(), filename)
      File.write!(backup_path, "fake backup content")

      try do
        conn = get(conn, ~p"/admin/backup/download/#{filename}")

        assert conn.status == 200
        assert conn.resp_headers |> List.keyfind("content-disposition", 0) |> elem(1) =~ filename
        assert conn.resp_body == "fake backup content"
      after
        File.rm(backup_path)
      end
    end

    test "rejects invalid filename pattern", %{conn: conn} do
      admin = admin_fixture()
      conn = log_in_user(conn, admin)
      # Use a filename that matches the route but fails validation
      conn = get(conn, ~p"/admin/backup/download/invalid_filename.tar.gz")

      assert conn.status == 400
      assert conn.resp_body =~ "Invalid filename"
    end
  end

  defp log_in_user(conn, user) do
    conn = Plug.Test.init_test_session(conn, %{})
    {:ok, token, _claims} = AshAuthentication.Jwt.token_for_user(user)
    conn |> Plug.Conn.put_session(:user_token, token)
  end
end
