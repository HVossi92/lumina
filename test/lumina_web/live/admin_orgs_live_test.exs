defmodule LuminaWeb.AdminOrgsLiveTest do
  use LuminaWeb.ConnCase

  import Lumina.Fixtures
  import Phoenix.LiveViewTest

  describe "AdminLive.Orgs" do
    setup do
      admin = admin_fixture()
      {:ok, admin: admin}
    end

    test "shows organizations list for admin", %{conn: conn, admin: admin} do
      _org1 = org_fixture(admin, %{name: "Org One", slug: "org-one"})
      _org2 = org_fixture(admin, %{name: "Org Two", slug: "org-two"})

      conn = log_in_user(conn, admin)
      {:ok, view, html} = live(conn, ~p"/admin/orgs")

      assert html =~ "Manage Organizations"
      assert html =~ "Org One"
      assert html =~ "Org Two"
      assert has_element?(view, "table")
    end

    test "redirects non-admin to dashboard with error", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      {:error, {:redirect, %{to: path, flash: flash}}} = live(conn, ~p"/admin/orgs")

      assert path == ~p"/"
      assert flash["error"] == "Only administrators can access this page"
    end

    test "redirects to sign-in when not authenticated", %{conn: conn} do
      {:error, {:redirect, %{to: path}}} = live(conn, ~p"/admin/orgs")

      assert path =~ "/sign-in"
    end

    test "creates new organization", %{conn: conn, admin: admin} do
      conn = log_in_user(conn, admin)
      {:ok, view, _html} = live(conn, ~p"/admin/orgs")

      view |> element("button", "New Organization") |> render_click()

      assert has_element?(view, "#org-form")

      view
      |> form("#org-form", %{"org" => %{"name" => "New Test Org", "slug" => "new-test-org"}})
      |> render_submit()

      assert render(view) =~ "Organization saved successfully"
      assert render(view) =~ "New Test Org"
    end

    test "edits existing organization", %{conn: conn, admin: admin} do
      org = org_fixture(admin, %{name: "Original Name", slug: "original-slug"})

      conn = log_in_user(conn, admin)
      {:ok, view, _html} = live(conn, ~p"/admin/orgs")

      view |> element("button[phx-click='edit_org'][phx-value-id='#{org.id}']") |> render_click()

      assert has_element?(view, "#org-form")

      view
      |> form("#org-form", %{"org" => %{"name" => "Updated Name", "slug" => "updated-slug"}})
      |> render_submit()

      assert render(view) =~ "Organization saved successfully"
      assert render(view) =~ "Updated Name"
    end

    test "deletes organization", %{conn: conn, admin: admin} do
      org = org_fixture(admin, %{name: "To Delete", slug: "to-delete"})

      conn = log_in_user(conn, admin)
      {:ok, view, _html} = live(conn, ~p"/admin/orgs")

      assert render(view) =~ "To Delete"

      view
      |> element("button[phx-click='delete_org'][phx-value-id='#{org.id}']")
      |> render_click()

      assert render(view) =~ "Organization deleted"
      refute render(view) =~ "To Delete"
    end

    test "generates invite link for owner role", %{conn: conn, admin: admin} do
      org = org_fixture(admin)

      conn = log_in_user(conn, admin)
      {:ok, view, _html} = live(conn, ~p"/admin/orgs")

      view
      |> element(
        "button[phx-click='generate_invite'][phx-value-id='#{org.id}'][phx-value-role='owner']"
      )
      |> render_click()

      html = render(view)
      assert html =~ "Invite link created"
      assert html =~ org.name
      assert has_element?(view, "#invite-url-input")
    end

    test "generates invite link for member role", %{conn: conn, admin: admin} do
      org = org_fixture(admin)

      conn = log_in_user(conn, admin)
      {:ok, view, _html} = live(conn, ~p"/admin/orgs")

      view
      |> element(
        "button[phx-click='generate_invite'][phx-value-id='#{org.id}'][phx-value-role='member']"
      )
      |> render_click()

      html = render(view)
      assert html =~ "Invite link created"
      assert html =~ org.name
      assert has_element?(view, "#invite-url-input")
    end

    test "shows member count", %{conn: conn, admin: admin} do
      org = org_fixture(admin)
      user1 = user_fixture()
      user2 = user_fixture()

      # Add members
      {:ok, _} =
        Lumina.Accounts.OrgMembership
        |> Ash.Changeset.for_create(:create, %{
          user_id: user1.id,
          org_id: org.id,
          role: :member
        })
        |> Ash.create(authorize?: false)

      {:ok, _} =
        Lumina.Accounts.OrgMembership
        |> Ash.Changeset.for_create(:create, %{
          user_id: user2.id,
          org_id: org.id,
          role: :member
        })
        |> Ash.create(authorize?: false)

      conn = log_in_user(conn, admin)
      {:ok, _view, html} = live(conn, ~p"/admin/orgs")

      # Should show 3 members (admin owner + 2 added members)
      assert html =~ "3"
    end

    test "cancels form", %{conn: conn, admin: admin} do
      conn = log_in_user(conn, admin)
      {:ok, view, _html} = live(conn, ~p"/admin/orgs")

      view |> element("button", "New Organization") |> render_click()
      assert has_element?(view, "#org-form")

      view |> element("button[phx-click='cancel_form']") |> render_click()
      refute has_element?(view, "#org-form")
    end

    test "shows empty state when no orgs", %{conn: conn, admin: admin} do
      conn = log_in_user(conn, admin)
      {:ok, _view, html} = live(conn, ~p"/admin/orgs")

      assert html =~ "No organizations yet"
    end
  end

  defp log_in_user(conn, user) do
    conn = Plug.Test.init_test_session(conn, %{})
    {:ok, token, _claims} = AshAuthentication.Jwt.token_for_user(user)
    conn |> Plug.Conn.put_session(:user_token, token)
  end
end
