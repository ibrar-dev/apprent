defmodule AppCount.Tenants.ExternalSyncCaseTest do
  use AppCount.DataCase
  alias AppCount.Tenants
  alias AppCount.Tenants.Tenancy
  @moduletag :tenants_external_sync

  test "external_sync returns error tuple when tenant has no property" do
    tenant = insert(:tenant, first_name: "James Robert", last_name: "Clark*")
    response = Tenants.sync_external_id(tenant.id, AppCount.Support.Yardi.FakeGateway)
    assert response == {:error, "Tenant not found"}
  end

  test "external_sync returns error tuple when name in Yardi does not match" do
    tenant = insert(:tenant, first_name: "George", last_name: "Washington")
    tenancy = insert(:tenancy, tenant: tenant)
    response = Tenants.sync_external_id(tenancy.id, AppCount.Support.Yardi.FakeGateway)

    assert response ==
             {:error, "Current tenant listed in Yardi as: James Robert Clark*(t0029810)"}
  end

  test "external_sync attaches external ID to tenant" do
    tenant = insert(:tenant, first_name: "James Robert", last_name: "Clark*")
    tenancy = insert(:tenancy, tenant: tenant)
    Tenants.sync_external_id(tenancy.id, AppCount.Support.Yardi.FakeGateway)
    reloaded = Repo.get(Tenancy, tenancy.id)
    assert reloaded.external_id == "t0029810"
  end
end
