defmodule LuminaWeb.ShareLiveTest do
  use LuminaWeb.ConnCase

  import Lumina.Fixtures
  import Phoenix.LiveViewTest

  describe "ShareLive.Show" do
    setup do
      user = user_fixture()
      org = org_fixture(user)
      album = album_fixture(org, user, %{name: "Shared Album"})
      share_link = share_link_fixture(album, user)
      {:ok, user: user, org: org, share_link: share_link, album: album}
    end

    test "shows shared album without authentication", %{conn: conn, share_link: share_link} do
      {:ok, _view, html} = live(conn, ~p"/share/#{share_link.token}")

      assert html =~ "Shared Album"
    end

    test "shows password gate for protected share", %{conn: conn, user: user, org: org} do
      album = album_fixture(org, user)
      share_link = share_link_fixture(album, user, %{password: "secret123"})

      {:ok, _view, html} = live(conn, ~p"/share/#{share_link.token}")

      assert html =~ "Password Required"
    end

    test "shows error for expired link", %{conn: conn, user: user, org: org} do
      album = album_fixture(org, user)

      expired_at = DateTime.utc_now() |> DateTime.add(-1, :day)
      share_link = share_link_fixture(album, user, %{expires_at: expired_at})

      {:ok, _view, html} = live(conn, ~p"/share/#{share_link.token}")

      assert html =~ "expired"
    end

    test "shows error for invalid token", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/share/invalid-token")

      assert html =~ "Invalid share link"
    end
  end
end
