defmodule LuminaWeb.OrgLiveTest do
  use LuminaWeb.ConnCase

  import Lumina.Fixtures
  import Phoenix.LiveViewTest

  describe "OrgLive.New" do
    setup do
      user = user_fixture()
      {:ok, user: user}
    end

    test "creates new organization", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/orgs/new")

      view
      |> form("#org-form",
        org: %{name: "New Org", slug: "new-org"}
      )
      |> render_submit()

      assert_redirect(view, ~p"/orgs/new-org")
    end
  end

  describe "OrgLive.Show" do
    setup do
      user = user_fixture()
      org = org_fixture(user, %{name: "Test Org", slug: "test-org"})
      {:ok, user: user, org: org}
    end

    test "shows org with albums", %{conn: conn, user: user, org: org} do
      _album = album_fixture(org, user, %{name: "Test Album"})

      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/orgs/#{org.slug}")

      assert html =~ "Test Org"
      assert html =~ "Test Album"
    end

    test "shows empty state when no albums", %{conn: conn, user: user, org: org} do
      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/orgs/#{org.slug}")

      assert html =~ "No albums"
    end
  end

  defp log_in_user(conn, user) do
    conn = Plug.Test.init_test_session(conn, %{})
    {:ok, token, _claims} = AshAuthentication.Jwt.token_for_user(user)
    conn |> Plug.Conn.put_session(:user_token, token)
  end
end
