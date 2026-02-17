defmodule LuminaWeb.AlbumShareLiveTest do
  use LuminaWeb.ConnCase

  import Lumina.Fixtures
  import Phoenix.LiveViewTest

  alias Lumina.Media.ShareLink

  describe "AlbumLive.Share" do
    setup do
      user = user_fixture()
      org = org_fixture(user)
      album = album_fixture(org, user, %{name: "Test Album"})
      {:ok, user: user, org: org, album: album}
    end

    test "renders share form", %{conn: conn, user: user, org: org, album: album} do
      conn = log_in_user(conn, user)
      {:ok, view, html} = live(conn, ~p"/orgs/#{org.slug}/albums/#{album.id}/share")

      assert html =~ "Share Test Album"
      assert has_element?(view, "#share-form")
      assert has_element?(view, "#days")
      assert has_element?(view, "#password")
    end

    test "redirects to sign-in when not authenticated", %{conn: conn, org: org, album: album} do
      {:error, {:redirect, %{to: path}}} =
        live(conn, ~p"/orgs/#{org.slug}/albums/#{album.id}/share")

      assert path =~ "/sign-in"
    end

    test "creates share link with default expiration", %{
      conn: conn,
      user: user,
      org: org,
      album: album
    } do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/orgs/#{org.slug}/albums/#{album.id}/share")

      view |> form("#share-form") |> render_submit()

      html = render(view)
      assert html =~ "Share link created successfully"
      assert has_element?(view, "#share-url-input")
    end

    test "creates share link with custom expiration", %{
      conn: conn,
      user: user,
      org: org,
      album: album
    } do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/orgs/#{org.slug}/albums/#{album.id}/share")

      view
      |> form("#share-form", %{"days" => "30", "password" => ""})
      |> render_submit()

      html = render(view)
      assert html =~ "Share link created successfully"
      assert has_element?(view, "#share-url-input")
    end

    test "creates password-protected share link", %{
      conn: conn,
      user: user,
      org: org,
      album: album
    } do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/orgs/#{org.slug}/albums/#{album.id}/share")

      view
      |> form("#share-form", %{"days" => "7", "password" => "secret123"})
      |> render_submit()

      html = render(view)
      assert html =~ "Share link created successfully"
      assert has_element?(view, "#share-url-input")

      # Verify the share link has a password
      share_url = view |> element("#share-url-input") |> render() |> extract_share_url()
      token = extract_token_from_url(share_url)

      {:ok, share_link} = ShareLink.by_token(token)
      assert !is_nil(share_link.password_hash)
    end

    test "creates public share link when password is empty", %{
      conn: conn,
      user: user,
      org: org,
      album: album
    } do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/orgs/#{org.slug}/albums/#{album.id}/share")

      view
      |> form("#share-form", %{"days" => "7", "password" => ""})
      |> render_submit()

      html = render(view)
      assert html =~ "Share link created successfully"

      # Verify the share link has no password
      share_url = view |> element("#share-url-input") |> render() |> extract_share_url()
      token = extract_token_from_url(share_url)

      {:ok, share_link} = ShareLink.by_token(token)
      assert is_nil(share_link.password_hash)
    end

    test "displays share URL after creation", %{conn: conn, user: user, org: org, album: album} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/orgs/#{org.slug}/albums/#{album.id}/share")

      view |> form("#share-form") |> render_submit()

      html = render(view)
      assert html =~ "/share/"
      assert has_element?(view, "#share-url-input")
    end

    test "redirects when org not found", %{conn: conn, user: user, album: album} do
      conn = log_in_user(conn, user)

      {:error, {:redirect, %{to: path}}} =
        live(conn, ~p"/orgs/nonexistent/albums/#{album.id}/share")

      assert path == ~p"/"
    end

    test "redirects when album not found", %{conn: conn, user: user, org: org} do
      conn = log_in_user(conn, user)

      {:error, {:redirect, %{to: path}}} =
        live(conn, ~p"/orgs/#{org.slug}/albums/invalid-id/share")

      assert path == ~p"/orgs/#{org.slug}"
    end
  end

  defp log_in_user(conn, user) do
    conn = Plug.Test.init_test_session(conn, %{})
    {:ok, token, _claims} = AshAuthentication.Jwt.token_for_user(user)
    conn |> Plug.Conn.put_session(:user_token, token)
  end

  defp extract_share_url(html) do
    case Regex.run(~r/value="([^"]+)"/, html) do
      [_, url] -> url
      _ -> nil
    end
  end

  defp extract_token_from_url(url) when is_binary(url) do
    case String.split(url, "/share/") do
      [_prefix, token] -> String.trim(token)
      _ -> nil
    end
  end

  defp extract_token_from_url(_), do: nil
end
