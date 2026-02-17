defmodule LuminaWeb.SignInLiveTest do
  use LuminaWeb.ConnCase

  import Lumina.Fixtures
  import Phoenix.LiveViewTest

  alias Lumina.Accounts.OrgInvite

  describe "sign in page" do
    test "shows Google sign-in without requiring invite", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/sign-in")

      assert has_element?(view, "#sign-in-with-google")
      assert has_element?(view, "#invite-form")
    end

    test "invalid invite keeps sign-in available and shows error", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/sign-in")

      view
      |> element("#invite-form")
      |> render_submit(%{"invite" => %{"token" => "not-a-valid-invite"}})

      assert has_element?(view, "#sign-in-with-google")
      assert has_element?(view, "#invite-form .alert-error")
    end

    test "valid invite redirects to sign-in with join return_to", %{conn: conn} do
      admin = admin_fixture()
      org = org_fixture(admin)

      {:ok, invite} =
        OrgInvite
        |> Ash.Changeset.for_create(:create, %{
          org_id: org.id,
          role: :member,
          expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
        })
        |> Ash.create(authorize?: false)

      {:ok, view, _html} = live(conn, ~p"/sign-in")

      view
      |> element("#invite-form")
      |> render_submit(%{"invite" => %{"token" => invite.token}})

      expected_path = "/sign-in?return_to=#{URI.encode_www_form("/join/#{invite.token}")}"
      assert_redirect(view, expected_path)
    end

    test "valid invite state hides invite form and highlights sign-in button", %{conn: conn} do
      admin = admin_fixture()
      org = org_fixture(admin)

      {:ok, invite} =
        OrgInvite
        |> Ash.Changeset.for_create(:create, %{
          org_id: org.id,
          role: :member,
          expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
        })
        |> Ash.create(authorize?: false)

      {:ok, view, _html} = live(conn, "/sign-in?return_to=/join/#{invite.token}")

      refute has_element?(view, "#invite-form")
      assert has_element?(view, "#sign-in-with-google.btn-success")
    end
  end
end
