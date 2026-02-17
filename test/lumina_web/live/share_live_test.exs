defmodule LuminaWeb.ShareLiveTest do
  use LuminaWeb.ConnCase

  import Lumina.Fixtures
  import Phoenix.LiveViewTest

  alias Lumina.Media.ShareLink

  @moduletag :serial
  describe "ShareLive.Show" do
    setup do
      user = user_fixture()
      org = org_fixture(user)
      album = album_fixture(org, user, %{name: "Shared Album"})
      share_link = share_link_fixture(album, user)
      {:ok, user: user, org: org, share_link: share_link, album: album}
    end

    defp set_view_count(share_link, count) do
      Enum.reduce(1..count, share_link, fn _, acc ->
        {:ok, updated} =
          acc
          |> Ash.Changeset.for_update(:increment_view_count)
          |> Ash.update()

        updated
      end)
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

    test "shows error when max_views limit reached", %{conn: conn, user: user, org: org} do
      album = album_fixture(org, user)
      share_link = share_link_fixture(album, user, %{max_views: 1})

      # Manually set view_count to max_views using increment_view_count
      updated_link = set_view_count(share_link, 1)

      {:ok, _view, html} = live(conn, ~p"/share/#{updated_link.token}")

      assert html =~ "maximum number of views"
    end

    test "allows access when view_count is below max_views", %{conn: conn, user: user, org: org} do
      album = album_fixture(org, user)
      share_link = share_link_fixture(album, user, %{max_views: 5})

      # Manually set view_count to 3 (below max) using increment_view_count
      updated_link = set_view_count(share_link, 3)

      {:ok, _view, html} = live(conn, ~p"/share/#{updated_link.token}")

      assert html =~ album.name
      refute html =~ "maximum number of views"
    end

    test "password authentication unlocks album", %{conn: conn, user: user, org: org} do
      album = album_fixture(org, user)
      share_link = share_link_fixture(album, user, %{password: "secret123"})

      {:ok, view, _html} = live(conn, ~p"/share/#{share_link.token}")

      assert render(view) =~ "Password Required"

      view
      |> form("#share-password-form", %{"password" => "secret123"})
      |> render_submit()

      assert render(view) =~ album.name
      refute render(view) =~ "Password Required"
    end

    test "wrong password shows error", %{conn: conn, user: user, org: org} do
      album = album_fixture(org, user)
      share_link = share_link_fixture(album, user, %{password: "secret123"})

      {:ok, view, _html} = live(conn, ~p"/share/#{share_link.token}")

      view
      |> form("#share-password-form", %{"password" => "wrong"})
      |> render_submit()

      assert render(view) =~ "Invalid password"
      assert render(view) =~ "Password Required"
    end

    test "view count increments on access", %{conn: conn, user: user, org: org} do
      album = album_fixture(org, user)
      share_link = share_link_fixture(album, user)

      assert share_link.view_count == 0

      {:ok, _view, _html} = live(conn, ~p"/share/#{share_link.token}")

      # Reload share link to check view count
      # Note: In tests, mount may be called twice (initial render + WebSocket connect),
      # so we check that view_count increased rather than exactly 1
      {:ok, updated_link} = ShareLink.by_token(share_link.token)

      assert updated_link.view_count >= 1
      assert updated_link.view_count <= 2
    end

    test "view count does not increment when max_views reached", %{
      conn: conn,
      user: user,
      org: org
    } do
      album = album_fixture(org, user)
      share_link = share_link_fixture(album, user, %{max_views: 1})

      # Set view_count to max using increment_view_count
      updated_link = set_view_count(share_link, 1)

      {:ok, _view, _html} = live(conn, ~p"/share/#{updated_link.token}")

      # Reload share link - view count should still be 1
      {:ok, final_link} = ShareLink.by_token(updated_link.token)

      assert final_link.view_count == 1
    end
  end
end
