defmodule LuminaWeb.AdminLiveTest do
  use LuminaWeb.ConnCase

  import Lumina.Fixtures
  import Phoenix.LiveViewTest

  describe "AdminLive.Backup" do
    test "shows backup page for admin", %{conn: conn} do
      admin = admin_fixture()
      conn = log_in_user(conn, admin)
      {:ok, _view, html} = live(conn, ~p"/admin/backup")

      assert html =~ "System Backup"
      assert html =~ "Download System Backup"
    end

    test "redirects non-admin to dashboard with error flash", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      {:error, {:redirect, %{to: path, flash: flash}}} = live(conn, ~p"/admin/backup")

      assert path == ~p"/"
      assert flash["error"] == "Only administrators can access this page"
    end

    test "redirects to sign-in when not authenticated", %{conn: conn} do
      {:error, {:redirect, %{to: path}}} = live(conn, ~p"/admin/backup")

      assert path =~ "/sign-in"
    end
  end

  describe "AdminLive.Users" do
    test "shows users page for admin", %{conn: conn} do
      admin = admin_fixture()
      conn = log_in_user(conn, admin)
      {:ok, view, html} = live(conn, ~p"/admin/users")

      assert html =~ "Manage Users"
      assert has_element?(view, "#admin-users-table")
    end

    test "redirects non-admin to dashboard with error flash", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      {:error, {:redirect, %{to: path, flash: flash}}} = live(conn, ~p"/admin/users")

      assert path == ~p"/"
      assert flash["error"] == "Only administrators can access this page"
    end

    test "redirects to sign-in when not authenticated", %{conn: conn} do
      {:error, {:redirect, %{to: path}}} = live(conn, ~p"/admin/users")

      assert path =~ "/sign-in"
    end

    test "admin can delete another user", %{conn: conn} do
      admin = admin_fixture()
      target = user_fixture()
      conn = log_in_user(conn, admin)
      {:ok, view, _html} = live(conn, ~p"/admin/users")

      assert has_element?(view, "#user-row-#{target.id}")

      view
      |> element("#user-row-#{target.id} button", "Delete")
      |> render_click()

      assert render(view) =~ "User deleted"
      refute has_element?(view, "#user-row-#{target.id}")
    end
  end

  defp log_in_user(conn, user) do
    conn = Plug.Test.init_test_session(conn, %{})
    {:ok, token, _claims} = AshAuthentication.Jwt.token_for_user(user)
    conn |> Plug.Conn.put_session(:user_token, token)
  end
end
