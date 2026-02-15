defmodule LuminaWeb.OrgLiveTest do
  use LuminaWeb.ConnCase

  import Lumina.Fixtures
  import Phoenix.LiveViewTest

  describe "OrgLive.New" do
    setup do
      admin = admin_fixture()
      {:ok, admin: admin}
    end

    test "creates new organization", %{conn: conn, admin: admin} do
      conn = log_in_user(conn, admin)
      {:ok, view, _html} = live(conn, ~p"/orgs/new")

      view
      |> form("#org-form",
        org: %{name: "New Org", slug: "new-org"}
      )
      |> render_submit()

      assert_redirect(view, ~p"/orgs/new-org")
    end

    test "creates new organization with slug generated from name when slug left empty", %{
      conn: conn,
      admin: admin
    } do
      conn = log_in_user(conn, admin)
      {:ok, view, _html} = live(conn, ~p"/orgs/new")

      view
      |> form("#org-form", org: %{name: "Auto Slug Org", slug: ""})
      |> render_submit()

      assert_redirect(view, ~p"/orgs/auto-slug-org")
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

    test "displays storage usage bar with correct usage and limit", %{
      conn: conn,
      user: user,
      org: org
    } do
      album = album_fixture(org, user)
      _photo = photo_fixture(album, user, %{file_size: 2_000_000})

      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/orgs/#{org.slug}")

      assert has_element?(view, "#org-storage-bar")
      bar_html = view |> element("#org-storage-bar") |> render()
      assert bar_html =~ "Storage:"
      assert bar_html =~ "4.0 GB"
      assert bar_html =~ "1.91 MB"
    end

    test "displays storage bar with 0 usage when org has no photos", %{
      conn: conn,
      user: user,
      org: org
    } do
      _album = album_fixture(org, user)

      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/orgs/#{org.slug}")

      assert has_element?(view, "#org-storage-bar")
      bar_html = view |> element("#org-storage-bar") |> render()
      assert bar_html =~ "Storage:"
      assert bar_html =~ "4.0 GB"
      assert bar_html =~ "0 B"
    end
  end

  defp log_in_user(conn, user) do
    conn = Plug.Test.init_test_session(conn, %{})
    {:ok, token, _claims} = AshAuthentication.Jwt.token_for_user(user)
    conn |> Plug.Conn.put_session(:user_token, token)
  end
end
