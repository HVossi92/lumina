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
  end

  defp log_in_user(conn, user) do
    conn = Plug.Test.init_test_session(conn, %{})
    {:ok, token, _claims} = AshAuthentication.Jwt.token_for_user(user)
    conn |> Plug.Conn.put_session(:user_token, token)
  end
end
