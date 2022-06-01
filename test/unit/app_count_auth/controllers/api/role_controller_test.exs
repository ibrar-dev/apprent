defmodule AppCountAuth.API.RoleControllerTest do
  use AppCount.Case
  alias AppCountAuth.API.RoleController
  alias AppCountAuth.Users.Admin

  setup do
    admin = %Admin{roles: MapSet.new([])}
    {:ok, super_admin: %Admin{roles: MapSet.new(["Super Admin"])}, admin: admin}
  end

  test "index", %{super_admin: super_admin, admin: admin} do
    assert RoleController.index(super_admin, %{}) == {:ok, :authorized}
    assert RoleController.index(admin, %{}) == {:error, :invalid_roles}
  end

  test "create", %{super_admin: super_admin, admin: admin} do
    assert RoleController.create(super_admin, %{}) == {:ok, :authorized}
    assert RoleController.create(admin, %{}) == {:error, :invalid_roles}
  end

  test "update", %{super_admin: super_admin, admin: admin} do
    assert RoleController.update(super_admin, %{}) == {:ok, :authorized}
    assert RoleController.update(admin, %{}) == {:error, :invalid_roles}
  end

  test "delete", %{super_admin: super_admin, admin: admin} do
    assert RoleController.delete(super_admin, %{}) == {:ok, :authorized}
    assert RoleController.delete(admin, %{}) == {:error, :invalid_roles}
  end
end
