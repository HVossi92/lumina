defmodule LuminaWeb.AuthControllerTest do
  use LuminaWeb.ConnCase

  require Ash.Query
  import Lumina.Fixtures

  alias Lumina.Accounts.User

  defp conn_with_flash(conn, session \\ %{}) do
    conn
    |> Plug.Test.init_test_session(session)
    |> Phoenix.Controller.fetch_flash([])
  end

  describe "success/4 (OAuth callback) – invite-only signup" do
    test "new user without valid invite: user is destroyed and redirected to sign-in", %{
      conn: conn
    } do
      user = user_fixture()
      user = Ash.load!(user, :org_memberships, authorize?: false)
      assert user.org_memberships == []

      conn =
        conn
        |> conn_with_flash()
        |> LuminaWeb.AuthController.success({:google, :callback}, user, nil)

      assert redirected_to(conn) == ~p"/sign-in"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "invitation"

      assert {:ok, list} = User |> Ash.Query.filter(id == ^user.id) |> Ash.read(authorize?: false)
      assert list == []
    end

    test "new user with valid invite in return_to: proceeds to sign-in", %{conn: conn} do
      admin = admin_fixture()
      org = org_fixture(admin)

      {:ok, invite} =
        Lumina.Accounts.OrgInvite
        |> Ash.Changeset.for_create(:create, %{
          org_id: org.id,
          role: :member,
          expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
        })
        |> Ash.create(authorize?: false)

      user = user_fixture()
      user = Ash.load!(user, :org_memberships, authorize?: false)
      assert user.org_memberships == []

      return_to = "/join/#{invite.token}"

      conn =
        conn
        |> conn_with_flash(%{return_to: return_to})
        |> LuminaWeb.AuthController.success({:google, :callback}, user, nil)

      assert redirected_to(conn) == return_to

      assert {:ok, [saved]} =
               User |> Ash.Query.filter(id == ^user.id) |> Ash.read(authorize?: false)

      assert saved.id == user.id
    end

    test "existing user (has org membership): proceeds regardless of return_to", %{conn: conn} do
      user = user_fixture()
      admin = admin_fixture()
      org = org_fixture(admin)

      {:ok, _} =
        Lumina.Accounts.OrgMembership
        |> Ash.Changeset.for_create(:create, %{
          user_id: user.id,
          org_id: org.id,
          role: :member
        })
        |> Ash.create(authorize?: false)

      user = Ash.load!(user, :org_memberships, authorize?: false)
      assert user.org_memberships != []

      conn =
        conn
        |> conn_with_flash()
        |> Plug.Test.init_test_session(%{})
        |> LuminaWeb.AuthController.success({:google, :callback}, user, nil)

      assert redirected_to(conn) == ~p"/"
    end
  end
end
