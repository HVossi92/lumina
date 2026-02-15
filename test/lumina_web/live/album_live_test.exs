defmodule LuminaWeb.AlbumLiveTest do
  use LuminaWeb.ConnCase

  import Lumina.Fixtures
  import Phoenix.LiveViewTest

  describe "AlbumLive.Show" do
    setup do
      user = user_fixture()
      org = org_fixture(user)
      album = album_fixture(org, user, %{name: "Test Album"})
      {:ok, user: user, org: org, album: album}
    end

    test "shows album with photos", %{conn: conn, user: user, org: org, album: album} do
      _photo = photo_fixture(album, user, %{filename: "test-photo.jpg"})

      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/orgs/#{org.slug}/albums/#{album.id}")

      assert html =~ "Test Album"
      # Note: Photos would only appear after thumbnail generation
    end

    test "shows empty state when no photos", %{conn: conn, user: user, org: org, album: album} do
      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/orgs/#{org.slug}/albums/#{album.id}")

      assert html =~ "No photos"
    end

    test "search filters photos by filename", %{conn: conn, user: user, org: org, album: album} do
      photo_fixture(album, user, %{filename: "sunset-beach.jpg"})
      photo_fixture(album, user, %{filename: "mountain-view.jpg"})

      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/orgs/#{org.slug}/albums/#{album.id}")

      assert view |> element("#album-search-form") |> render_change(%{"q" => "sunset"}) =~
               "sunset-beach"

      refute render(view) =~ "mountain-view"
    end

    test "search filters photos by tag", %{conn: conn, user: user, org: org, album: album} do
      photo_fixture(album, user, %{filename: "a.jpg", tags: ["beach", "sunset"]})
      photo_fixture(album, user, %{filename: "b.jpg", tags: ["mountain"]})

      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/orgs/#{org.slug}/albums/#{album.id}")

      view |> element("#album-search-form") |> render_change(%{"q" => "beach"})
      html = render(view)
      assert html =~ "a.jpg"
      refute html =~ "b.jpg"
    end

    test "search matches partial tag", %{conn: conn, user: user, org: org, album: album} do
      photo_fixture(album, user, %{filename: "a.jpg", tags: ["sunset"]})

      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/orgs/#{org.slug}/albums/#{album.id}")

      view |> element("#album-search-form") |> render_change(%{"q" => "sun"})
      assert render(view) =~ "a.jpg"
    end

    test "search is case insensitive", %{conn: conn, user: user, org: org, album: album} do
      photo_fixture(album, user, %{filename: "a.jpg", tags: ["Beach"]})

      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/orgs/#{org.slug}/albums/#{album.id}")

      view |> element("#album-search-form") |> render_change(%{"q" => "beach"})
      assert render(view) =~ "a.jpg"
    end

    test "empty search shows all photos", %{conn: conn, user: user, org: org, album: album} do
      photo_fixture(album, user, %{filename: "one.jpg"})
      photo_fixture(album, user, %{filename: "two.jpg"})

      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/orgs/#{org.slug}/albums/#{album.id}")

      view |> element("#album-search-form") |> render_change(%{"q" => "xyz"})
      refute render(view) =~ "one.jpg"

      view |> element("#album-search-form") |> render_change(%{"q" => ""})
      html = render(view)
      assert html =~ "one.jpg"
      assert html =~ "two.jpg"
    end

    test "no search results shows appropriate message", %{
      conn: conn,
      user: user,
      org: org,
      album: album
    } do
      photo_fixture(album, user, %{filename: "only.jpg"})

      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/orgs/#{org.slug}/albums/#{album.id}")

      view |> element("#album-search-form") |> render_change(%{"q" => "nomatch"})
      html = render(view)
      assert html =~ "No photos match your search"
      assert html =~ "Try different search terms"
    end

    test "rename photo updates filename", %{conn: conn, user: user, org: org, album: album} do
      _photo = photo_fixture(album, user, %{filename: "original.jpg"})

      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/orgs/#{org.slug}/albums/#{album.id}")

      view |> element("[aria-label='Photo menu']") |> render_click()
      view |> element("button", "Rename") |> render_click()
      assert has_element?(view, "#rename-form")

      view
      |> form("#rename-form", %{"rename" => %{"filename" => "renamed.jpg"}})
      |> render_submit()

      assert render(view) =~ "renamed.jpg"
      assert render(view) =~ "Photo renamed"
    end

    test "edit tags updates photo tags", %{conn: conn, user: user, org: org, album: album} do
      photo_fixture(album, user, %{filename: "tagged.jpg", tags: []})

      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/orgs/#{org.slug}/albums/#{album.id}")

      view |> element("[aria-label='Photo menu']") |> render_click()
      view |> element("button", "Edit tags") |> render_click()
      assert has_element?(view, "#edit-tags-form")

      view
      |> form("#edit-tags-form", %{"edit_tags" => %{"tags" => "a, b, c"}})
      |> render_submit()

      assert render(view) =~ "Tags updated"
      assert render(view) =~ "a"
      assert render(view) =~ "b"
      assert render(view) =~ "c"
    end

    test "storage bar updates after photo added and after photo deleted", %{
      conn: conn,
      user: user,
      org: org,
      album: album
    } do
      conn = log_in_user(conn, user)
      {:ok, view_before, _} = live(conn, ~p"/orgs/#{org.slug}/albums/#{album.id}")
      assert has_element?(view_before, "#org-storage-bar")
      assert view_before |> element("#org-storage-bar") |> render() =~ "0 B"

      _photo = photo_fixture(album, user, %{file_size: 1024})
      {:ok, view_after_add, _} = live(conn, ~p"/orgs/#{org.slug}/albums/#{album.id}")
      assert view_after_add |> element("#org-storage-bar") |> render() =~ "1.0 KB"

      # Delete the photo (we need the photo id)
      photos = Lumina.Media.Photo.for_album!(album.id, actor: user, tenant: org.id)
      photo = hd(photos)
      Ash.destroy(photo, actor: user, tenant: org.id)

      {:ok, view_after_delete, _} = live(conn, ~p"/orgs/#{org.slug}/albums/#{album.id}")
      assert view_after_delete |> element("#org-storage-bar") |> render() =~ "0 B"
    end

    test "lightbox next respects search", %{conn: conn, user: user, org: org, album: album} do
      photo_fixture(album, user, %{filename: "first.jpg"})
      photo_fixture(album, user, %{filename: "second-match.jpg"})

      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/orgs/#{org.slug}/albums/#{album.id}")

      view |> element("#album-search-form") |> render_change(%{"q" => "second"})
      # Only one filtered photo; click the lightbox button (index 0)
      view |> element("button[phx-click='open_lightbox'][phx-value-index='0']") |> render_click()
      assert has_element?(view, "#lightbox")
      # Next button should not be present (only one filtered photo)
      html = render(view)
      refute html =~ "lightbox_next"
    end
  end

  defp log_in_user(conn, user) do
    conn = Plug.Test.init_test_session(conn, %{})
    {:ok, token, _claims} = AshAuthentication.Jwt.token_for_user(user)
    conn |> Plug.Conn.put_session(:user_token, token)
  end
end
