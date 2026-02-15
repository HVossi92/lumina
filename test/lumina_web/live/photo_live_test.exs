defmodule LuminaWeb.PhotoLiveTest do
  use LuminaWeb.ConnCase

  import Lumina.Fixtures
  import Phoenix.LiveViewTest

  describe "PhotoLive.Upload" do
    setup do
      user = user_fixture()
      org = org_fixture(user)
      album = album_fixture(org, user, %{name: "Upload Album"})
      {:ok, user: user, org: org, album: album}
    end

    test "renders upload form", %{conn: conn, user: user, org: org, album: album} do
      conn = log_in_user(conn, user)
      {:ok, view, html} = live(conn, ~p"/orgs/#{org.slug}/albums/#{album.id}/upload")

      assert html =~ "Upload Photos"
      assert html =~ album.name
      assert has_element?(view, "#upload-form")
    end

    test "redirects to sign-in when not authenticated", %{conn: conn, org: org, album: album} do
      {:error, {:redirect, %{to: path}}} =
        live(conn, ~p"/orgs/#{org.slug}/albums/#{album.id}/upload")

      assert path =~ "/sign-in"
    end

    @storage_limit_message "Organization storage limit (4 GB) would be exceeded"
    @limit_bytes 4 * 1024 * 1024 * 1024

    test "rejects upload and shows error when storage limit would be exceeded", %{
      conn: conn,
      user: user,
      org: org,
      album: album
    } do
      # Org already at limit - 1 byte
      _photo = photo_fixture(album, user, %{file_size: @limit_bytes - 1})

      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/orgs/#{org.slug}/albums/#{album.id}/upload")

      # Upload a 2-byte file so total would exceed 4GB
      small_jpeg = <<0xFF, 0xD8>>

      file_input =
        file_input(view, "#upload-form", :photos, [
          %{
            name: "tiny.jpg",
            content: small_jpeg,
            size: 2,
            type: "image/jpeg"
          }
        ])

      render_upload(file_input, "tiny.jpg", 100)
      view |> form("#upload-form") |> render_submit()

      # Should stay on upload page with error flash (no redirect)
      assert render(view) =~ @storage_limit_message
      assert render(view) =~ "Upload Photos"
    end
  end

  defp log_in_user(conn, user) do
    conn = Plug.Test.init_test_session(conn, %{})
    {:ok, token, _claims} = AshAuthentication.Jwt.token_for_user(user)
    conn |> Plug.Conn.put_session(:user_token, token)
  end
end
