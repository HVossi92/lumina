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

      assert {:ok, memberships} =
               Lumina.Accounts.OrgMembership
               |> Ash.Query.filter(user_id == ^user.id and org_id == ^org.id)
               |> Ash.read(authorize?: false)

      assert length(memberships) == 1
    end

    test "new user invited once can sign in later without invite and is not deleted", %{
      conn: conn
    } do
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

      _first_conn =
        conn
        |> conn_with_flash(%{return_to: "/join/#{invite.token}"})
        |> LuminaWeb.AuthController.success({:google, :callback}, user, nil)

      second_conn =
        build_conn()
        |> conn_with_flash()
        |> LuminaWeb.AuthController.success({:google, :callback}, user, nil)

      assert redirected_to(second_conn) == ~p"/"

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

  describe "register_with_password – forbidden" do
    test "password registration is forbidden (policy blocks public signup)" do
      changeset =
        User
        |> Ash.Changeset.for_create(:register_with_password, %{
          email: "newuser@example.com",
          password: "Password123!",
          password_confirmation: "Password123!"
        })

      assert {:error, %Ash.Error.Forbidden{}} = Ash.create(changeset)
    end
  end
end
