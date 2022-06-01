defmodule AppCount.Tenants.TenancyRepo do
  use AppCount.Core.GenericRepo,
    schema: AppCount.Tenants.Tenancy,
    preloads: [:tenant, :unit]

  alias AppCount.Core.Clock

  def current_tenancies_query(date \\ AppCount.current_date()) do
    from(
      t in Tenancy,
      where: t.start_date <= ^date,
      where: is_nil(t.actual_move_out) or t.actual_move_out > ^date
    )
  end

  def latest_tenancy_query() do
    from(
      t in @schema,
      join: tenant in assoc(t, :tenant),
      distinct: tenant.id,
      order_by: [desc: t.start_date]
    )
  end

  # We should allow tenancies that are going to start in the next 30 days as well.
  # This will allow future residents to get accounts and to log in.
  # This may need to be adjusted to 14 days.
  def current_tenancies_for_tenant(tenant_id, date \\ Clock.thirty_days(), schema \\ "dasmen") do
    date
    |> current_tenancies_query()
    |> where([t], t.tenant_id == ^tenant_id)
    |> Repo.all(prefix: schema)
  end

  def active_tenancy_for_tenant(tenant_id, tenancy_id \\ nil) do
    # TODO throughout the application we tend to assume any tenant can only have one
    # active tenancy at a time, this is not actually the case. It will need to be handled in each individual case
    if tenancy_id do
      get(tenancy_id)
    else
      List.first(current_tenancies_for_tenant(tenant_id))
    end
  end

  # For the unit we want to only get the current one. Not thirty days out.
  def current_tenancies_for_unit(unit_id, date \\ AppCount.current_date()) do
    date
    |> current_tenancies_query()
    |> where([t], t.unit_id == ^unit_id)
    |> Repo.all()
  end

  def property_tenancies_query(property_id, as_of \\ AppCount.current_date()) do
    current_tenancies_query(as_of)
    |> join(:inner, [t], unit in assoc(t, :unit))
    |> where([_, unit], unit.property_id == ^property_id)
  end

  def tenancies_with_property_query() do
    from(
      tenancy in Tenancy,
      join: unit in assoc(tenancy, :unit),
      join: property in assoc(unit, :property)
    )
  end

  def tenancy_property_settings(tenancy_id) do
    tenancies_with_property_query()
    |> join(:inner, [tenancy, unit, property], setting in assoc(property, :setting))
    |> where([t], t.id == ^tenancy_id)
    |> select([_, _, _, settings], settings)
    |> Repo.one()
  end
end
