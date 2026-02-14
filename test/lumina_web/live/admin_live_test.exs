defmodule LuminaWeb.AdminLiveTest do
  use LuminaWeb.ConnCase

  import Lumina.Fixtures
  import Phoenix.LiveViewTest

  describe "AdminLive.Backup" do
    setup do
      user = user_fixture()
      {:ok, user: user}
    end

    test "shows password gate when not authenticated", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/admin/backup")

      assert html =~ "Admin Access Required"
      assert html =~ "Admin Password"
    end

    test "shows backup page after successful authentication", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/admin/backup")

      html =
        view
        |> form("form", password: "change-me-in-production")
        |> render_submit()

      assert html =~ "System Backup"
      assert html =~ "Download System Backup"
    end

    test "shows auth form after wrong password", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/admin/backup")

      view
      |> form("form", password: "wrong-password")
      |> render_submit()

      # After wrong password, the view should still show the auth form
      html = render(view)
      assert html =~ "Admin Access Required"
      refute html =~ "System Backup"
    end

    test "redirects to sign-in when not authenticated", %{conn: conn} do
      {:error, {:redirect, %{to: path}}} = live(conn, ~p"/admin/backup")

      assert path =~ "/sign-in"
    end
  end

  defp log_in_user(conn, user) do
    conn = Plug.Test.init_test_session(conn, %{})
    {:ok, token, _claims} = AshAuthentication.Jwt.token_for_user(user)
    conn |> Plug.Conn.put_session(:user_token, token)
  end
end
