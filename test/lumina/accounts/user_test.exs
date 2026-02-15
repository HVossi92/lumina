defmodule Lumina.Accounts.UserTest do
  use Lumina.DataCase

  import Lumina.Fixtures

  alias Lumina.Accounts.User

  describe "admin user policies" do
    test "admin can list users" do
      admin = admin_fixture()
      _other = user_fixture()

      users = Ash.read!(User, actor: admin)

      assert length(users) >= 2
      assert Enum.any?(users, &(&1.id == admin.id))
    end

    test "admin can destroy another user" do
      admin = admin_fixture()
      other = user_fixture()

      assert :ok = Ash.destroy(other, actor: admin)
      assert {:error, _} = Ash.get(User, other.id, authorize?: false)
    end

    test "non-admin cannot list users" do
      user = user_fixture()
      _other = user_fixture()

      # Non-admin does not see other users (empty list or error)
      result = Ash.read(User, actor: user)
      assert result == {:ok, []} or match?({:error, _}, result)

      case result do
        {:ok, list} -> assert list == []
        _ -> :ok
      end
    end

    test "non-admin cannot destroy a user" do
      regular_user = user_fixture()
      target = user_fixture()

      assert {:error, _} = Ash.destroy(target, actor: regular_user)
    end

    test "admin cannot destroy themselves" do
      admin = admin_fixture()

      assert {:error, _} = Ash.destroy(admin, actor: admin)
    end
  end
end
