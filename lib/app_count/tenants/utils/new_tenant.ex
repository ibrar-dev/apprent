defmodule AppCount.Tenants.Utils.NewTenant do
  alias AppCount.Tenants.TenantRepo
  alias AppCount.Leasing.Utils.CreateNewTenancy

  def new_tenant(%{lease_params: lease_params, tenant_params: tenant_params}) do
    {:ok, tenant} = TenantRepo.insert(tenant_params)

    lease_params
    |> Map.put(:tenant_id, tenant.id)
    |> CreateNewTenancy.create_new_tenancy()
  end
end
