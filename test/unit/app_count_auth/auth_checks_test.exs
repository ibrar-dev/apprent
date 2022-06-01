defmodule AppcountAuth.AuthChecksTest do
  use AppCount.Case
  alias AppCountAuth.Users.Admin
  alias AppCountAuth.AuthChecks

  test ":module_enabled" do
    admin = %Admin{features: %{maintenance: true}}
    result = AuthChecks.auth_checks(admin, module_enabled: :maintenance)
    assert result == {:ok, :authorized}

    result =
      AuthChecks.auth_checks(admin, module_enabled: :maintenance, module_enabled: :accounting)

    assert result == {:error, :module_disabled}
  end

  test ":super_admin" do
    admin = %Admin{features: %{maintenance: true}, roles: MapSet.new(["Super Admin"])}
    result = AuthChecks.auth_checks(admin, module_enabled: :maintenance, super_admin: true)
    assert result == {:ok, :authorized}

    admin = %Admin{features: %{maintenance: true}, roles: MapSet.new(["Admin"])}
    result = AuthChecks.auth_checks(admin, module_enabled: :maintenance, super_admin: true)
    assert result == {:error, :invalid_roles}
  end

  test ":property_access" do
    admin = %Admin{features: %{maintenance: true}, property_ids: [1, 2]}
    result = AuthChecks.auth_checks(admin, module_enabled: :maintenance, property_access: 2)
    assert result == {:ok, :authorized}

    result = AuthChecks.auth_checks(admin, module_enabled: :maintenance, property_access: 3)
    assert result == {:error, :no_property_permission}
  end

  test ":role_auth" do
    admin = %Admin{features: %{maintenance: true}, roles: MapSet.new(["Regional"])}
    result = AuthChecks.auth_checks(admin, module_enabled: :maintenance, role_auth: "Regional")
    assert result == {:ok, :authorized}

    result = AuthChecks.auth_checks(admin, module_enabled: :maintenance, role_auth: "Admin")
    assert result == {:error, :invalid_roles}
  end

  test ":custom" do
    admin = %Admin{features: %{maintenance: true}, roles: MapSet.new(["Regional"])}
    auth_func = fn user -> user.__struct__ == Admin end
    error_msg = "This user is not an admin"

    result =
      AuthChecks.auth_checks(admin, module_enabled: :maintenance, custom: {auth_func, error_msg})

    assert result == {:ok, :authorized}

    tenant = %AppCountAuth.Users.Tenant{features: %{maintenance: true}}

    result =
      AuthChecks.auth_checks(tenant, module_enabled: :maintenance, custom: {auth_func, error_msg})

    assert result == {:error, error_msg}
  end

  test "multiple auth checks of the same kind and ordering" do
    admin = %Admin{
      features: %{maintenance: true},
      property_ids: [1, 2, 3, 4],
      roles: MapSet.new(["Regional"])
    }

    result =
      AuthChecks.auth_checks(admin, module_enabled: :maintenance, module_enabled: :accounting)

    assert result == {:error, :module_disabled}

    result =
      AuthChecks.auth_checks(admin,
        module_enabled: :maintenance,
        property_access: 3,
        property_access: 4,
        property_access: 5
      )

    assert result == {:error, :no_property_permission}

    result =
      AuthChecks.auth_checks(admin,
        module_enabled: :maintenance,
        property_access: 3,
        property_access: 4,
        property_access: 5,
        module_enabled: :accounting
      )

    assert result == {:error, :module_disabled}
  end
end
