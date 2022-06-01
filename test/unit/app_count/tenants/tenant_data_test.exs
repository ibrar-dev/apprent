defmodule AppCount.Tenants.TenantDataTest do
  use AppCount.DataCase
  import AppCount.LeaseHelper
  alias AppCount.Tenants

  @moduletag :tenant_data

  setup do
    %{tenants: [tenant], unit: unit} = insert_lease()
    admin = %AppCountAuth.Users.Admin{property_ids: [unit.property_id], client_schema: "dasmen"}
    {:ok, tenant: tenant, admin: admin, unit: unit}
  end

  @tag :slow
  test "get_tenant", %{admin: admin, tenant: tenant} do
    result = Tenants.get_tenant(admin, tenant.id)

    assert result.id == tenant.id
    assert length(result.leases) == 1
    refute result.invalid_email
  end

  @tag :slow
  test "get_tenant with bounce", ~M[admin, tenant] do
    AppCount.Messaging.BounceRepo.insert(%{target: tenant.email})
    result = Tenants.get_tenant(admin, tenant.id)

    assert result.id == tenant.id
    assert length(result.leases) == 1
    assert result.invalid_email
  end

  test "basic_tenant_info", %{unit: unit, tenant: tenant} do
    result = Tenants.Utils.TenantData.basic_tenant_info(tenant.id, unit.id)
    assert result.name == "#{tenant.first_name} #{tenant.last_name}"
  end
end
