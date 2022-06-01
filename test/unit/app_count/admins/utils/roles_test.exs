defmodule AppCount.Admins.Utils.RolesTest do
  use AppCount.DataCase
  alias AppCount.Admins.Utils.Roles
  alias AppCount.Core.ClientSchema

  setup do
    admin = insert(:admin)
    # Why 3 roles? This way we can test all possible scenarios:
    # 1) properties permissions where the 'write' permission needs to "overwrite" the 'read'
    # 2) tenants permissions where there is no entry in other roles at all
    # 3) techs permissions where there are 2 roles with the same permission
    role1 = insert(:role, permissions: %{properties: :write, tenants: :read})
    role2 = insert(:role, permissions: %{properties: :read, techs: :read})
    role3 = insert(:role, permissions: %{accounts: :write, techs: :read})
    AppCount.Admins.RoleRepo.attach_role_to_admin("dasmen", admin, role1)
    AppCount.Admins.RoleRepo.attach_role_to_admin("dasmen", admin, role2)
    AppCount.Admins.RoleRepo.attach_role_to_admin("dasmen", admin, role3)
    {:ok, admin: admin, roles: [role1, role2, role3]}
  end

  test "list_roles", %{roles: [role1, role2, role3]} do
    expected =
      [role1, role2, role3]
      |> Enum.map(&Map.take(&1, [:id, :name, :permissions]))

    assert Roles.list_roles(ClientSchema.new("dasmen")) == expected
  end

  test "collect_admin_roles yields a correct map of roles", %{admin: admin, roles: roles} do
    result = Roles.collect_admin_roles(ClientSchema.new("dasmen", admin.id))
    expected = [properties: :write, tenants: :read, techs: :read, accounts: :write]

    expected
    |> Enum.each(fn {resource, action} ->
      assert result[resource] == action
    end)

    [_, _, to_detach] = roles
    AppCount.Admins.RoleRepo.detach_role_from_admin("dasmen", admin, to_detach)

    result = Roles.collect_admin_roles(admin)
    expected = [properties: :write, tenants: :read, techs: :read]

    expected
    |> Enum.each(fn {resource, action} ->
      assert result[resource] == action
    end)

    refute result[:accounts]
  end
end
