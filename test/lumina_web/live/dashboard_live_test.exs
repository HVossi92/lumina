defmodule LuminaWeb.DashboardLiveTest do
  use LuminaWeb.ConnCase

  import Lumina.Fixtures
  import Phoenix.LiveViewTest

  describe "Dashboard" do
    setup do
      user = user_fixture()
      {:ok, user: user}
    end

    test "shows user's organizations", %{conn: conn, user: user} do
      _org1 = org_fixture(user, %{name: "Org One", slug: "org-one"})
      _org2 = org_fixture(user, %{name: "Org Two", slug: "org-two"})

      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "Org One"
      assert html =~ "Org Two"
    end

    test "shows empty state when no orgs", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "No organizations"
    end

    test "redirects to sign-in when not authenticated", %{conn: conn} do
      {:error, {:redirect, %{to: path}}} = live(conn, ~p"/")

      assert path =~ "/sign-in"
    end
  end

  defp log_in_user(conn, user) do
    conn = Plug.Test.init_test_session(conn, %{})
    {:ok, token, _claims} = AshAuthentication.Jwt.token_for_user(user)
    conn |> Plug.Conn.put_session(:user_token, token)
  end
end
