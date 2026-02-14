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
  end

  defp log_in_user(conn, user) do
    conn = Plug.Test.init_test_session(conn, %{})
    {:ok, token, _claims} = AshAuthentication.Jwt.token_for_user(user)
    conn |> Plug.Conn.put_session(:user_token, token)
  end
end
