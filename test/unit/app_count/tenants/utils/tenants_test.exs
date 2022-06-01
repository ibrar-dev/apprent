defmodule AppCount.Tenants.Utils.TenantsTest do
  use AppCount.DataCase
  import AppCount.LeaseHelper
  alias AppCount.Tenants
  @moduletag :tenants_utils_tenants

  setup do
    %{unit: unit, tenants: [tenant]} = insert_lease()
    admin = %AppCountAuth.Users.Admin{property_ids: [unit.property_id], client_schema: "dasmen"}
    {:ok, unit: unit, admin: admin, tenant: tenant}
  end

  test "list_tenants", %{admin: admin, tenant: tenant, unit: unit} do
    [result] = Tenants.list_tenants(admin)
    assert [result] == Tenants.list_tenants(admin, unit.property_id)
    assert [] == Tenants.list_tenants(admin, 0)
    assert result.id == tenant.id
    assert is_nil(result.account)
    assert result.logins == []
  end

  test "list_tenants_min", %{admin: admin, tenant: tenant, unit: unit} do
    [result] = Tenants.list_tenants_min(admin)
    assert result.id == tenant.id
    assert result.email == tenant.email
    assert result.name == "#{tenant.first_name} #{tenant.last_name}"
    assert hd(result.leases)["number"] == unit.number
  end
end
