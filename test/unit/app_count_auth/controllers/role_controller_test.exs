defmodule AppCountAuth.RoleControllerTest do
  use AppCount.Case
  alias AppCountAuth.RoleController
  alias AppCountAuth.Users.Admin

  setup do
    admin = %Admin{roles: MapSet.new([])}
    {:ok, super_admin: %Admin{roles: MapSet.new(["Super Admin"])}, admin: admin}
  end

  test "index", %{super_admin: super_admin, admin: admin} do
    assert RoleController.index(super_admin, %{}) == {:ok, :authorized}
    assert RoleController.index(admin, %{}) == {:error, :invalid_roles}
  end
end
