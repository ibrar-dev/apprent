defmodule AppCount.Tenants do
  alias AppCount.Tenants.Utils.CreateTenant
  alias AppCount.Tenants.Utils.ExternalIdSync
  alias AppCount.Tenants.Utils.Ledgers
  alias AppCount.Tenants.Utils.Pets
  alias AppCount.Tenants.Utils.Queries
  alias AppCount.Tenants.Utils.TenantData
  alias AppCount.Tenants.Utils.Tenancies
  alias AppCount.Tenants.Utils.Tenants
  alias AppCount.Tenants.Utils.Vehicles

  def get_tenant(admin, id), do: TenantData.get_tenant(admin, id)

  def list_tenancies(admin, property_id), do: Tenancies.list_tenancies(admin, property_id)
  def get_tenancy(admin, id), do: Tenancies.get_tenancy(admin, id)
  def update_tenancy(id, params), do: Tenancies.update_tenancy(id, params)

  def create_tenant(params, opts \\ []), do: CreateTenant.create_tenant(params, opts)
  def create_new_tenant(params), do: CreateTenant.create_new_tenant(params)

  def update_tenant(id, params), do: Tenants.update_tenant(id, params)
  def list_tenants(admin), do: Tenants.list_tenants(admin)
  def list_tenants(admin, property_id), do: Tenants.list_tenants(admin, property_id)
  def list_tenants_min(admin), do: Tenants.list_tenants_min(admin)
  def property_for(tenant_id), do: Tenants.property_for(tenant_id)
  def send_individual_email(params), do: Tenants.send_individual_email(params)

  def sync_external_id(tenant_id, gateway \\ Yardi.Gateway),
    do: ExternalIdSync.sync_external_id(tenant_id, gateway)

  def list_tenants_balance(property_id), do: Queries.list_tenants_balance(property_id)
  def navbar_search(admin, term), do: Queries.navbar_search(admin, term)
  def tenant_search(admin, name, property_id), do: Queries.tenant_search(admin, name, property_id)

  def get_residents_by_type(admin, property_id, type),
    do: Queries.get_residents_by_type(admin, property_id, type)

  def balance_query(opts \\ []), do: Ledgers.balance_query(opts)
  def ledger_query(opts \\ []), do: Ledgers.ledger_query(opts)

  def download_ledger(tenant_id, lease_id, date \\ AppCount.current_date()),
    do: AppCount.Exports.Ledger.get_ledger(tenant_id, lease_id, date)

  def create_pet(params), do: Pets.create_pet(params)
  def update_pet(id, params), do: Pets.update_pet(id, params)
  def delete_pet(admin, id), do: Pets.delete_pet(admin, id)

  def create_vehicle(params), do: Vehicles.create_vehicle(params)
  def update_vehicle(id, params), do: Vehicles.update_vehicle(id, params)
  def delete_vehicle(admin, id), do: Vehicles.delete_vehicle(admin, id)

  def clear_bounces(tenant_id), do: Tenants.clear_bounces(tenant_id)
end
