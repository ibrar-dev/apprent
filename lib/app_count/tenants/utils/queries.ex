defmodule AppCount.Tenants.Utils.Queries do
  alias AppCount.Repo
  alias AppCount.Tenants.Tenant
  alias AppCount.Leases.Lease
  alias AppCount.Tenants.TenantRepo
  alias AppCount.Properties.UnitRepo
  import Ecto.Query

  def get_residents_by_type(admin, property_id, type) do
    lease_query =
      from(
        l in Lease,
        join: o in assoc(l, :occupancies),
        join: u in assoc(l, :unit),
        where: u.property_id == ^property_id and u.property_id in ^admin.property_ids,
        select: %{
          id: l.id,
          tenant_id: o.tenant_id,
          unit: u.number
        }
      )
      |> filter_query(type, AppCount.current_time())

    from(
      t in Tenant,
      join: l in subquery(lease_query),
      on: l.tenant_id == t.id,
      select: %{
        id: t.id,
        name: fragment("? || ' ' || ?", t.first_name, t.last_name),
        checked: true,
        property_id: type(^property_id, :integer),
        type: ^type,
        unit: l.unit,
        email: t.email,
        lease_id: l.id
      },
      distinct: t.id
    )
    |> Repo.all(prefix: admin.client_schema)
  end

  def list_tenants_balance(property_id) do
    now = AppCount.current_time()

    AppCount.Ledgers.CustomerLedgerRepo.ledger_balances_query()
    |> where([ledger], ledger.property_id == ^property_id)
    |> select([ledger, payment, charge], %{
      id: ledger.id,
      balance: coalesce(charge.sum, 0) - coalesce(payment.sum, 0)
    })
    |> subquery
    |> join(:inner, [ledger], tenancy in AppCount.Tenants.Tenancy,
      on: tenancy.customer_ledger_id == ledger.id
    )
    |> join(:inner, [ledger, tenancy], tenant in assoc(tenancy, :tenant))
    |> join(:inner, [ledger, tenancy], unit in assoc(tenancy, :unit))
    |> join(:left, [ledger], lease in AppCount.Leasing.Lease,
      on: lease.customer_ledger_id == ledger.id
    )
    |> distinct([ledger, tenancy], tenancy.id)
    |> select([ledger, tenancy, tenant, unit, lease], %{
      id: tenancy.id,
      current: tenancy.start_date <= ^now and is_nil(tenancy.actual_move_out),
      past: not is_nil(tenancy.actual_move_out),
      future: tenancy.start_date > ^now,
      unit: unit.number,
      start_date: max(lease.start_date),
      end_date: max(lease.end_date),
      last_name: tenant.last_name,
      first_name: tenant.first_name,
      balance: ledger.balance
    })
    |> group_by([ledger, tenancy, tenant, unit], [ledger.balance, tenancy.id, tenant.id, unit.id])
    |> Repo.all()
  end

  def navbar_search(admin, term) do
    tenants = tenant_search(admin, term)
    units = unit_search(admin, term)
    tenants ++ units
  end

  def tenant_search(admin, name) do
    TenantRepo.tenant_search(admin, name)
  end

  def unit_search(admin, term) do
    UnitRepo.navbar_search(admin.property_ids, term)
  end

  def tenant_search(admin, name, property_id) do
    comp = "%#{String.upcase(name)}%"

    from(
      t in Tenant,
      join: te in assoc(t, :tenancies),
      join: u in assoc(te, :unit),
      join: p in assoc(u, :property),
      select: %{
        id: t.id,
        name: fragment("? || ' ' || ?", t.first_name, t.last_name),
        property: p.name,
        unit: u.number
      },
      where: p.id in ^admin.property_ids,
      where: u.property_id == ^property_id,
      where:
        fragment("upper(? ||  ' ' || ?)", t.first_name, t.last_name)
        |> like(^comp),
      group_by: [t.id, p.id, u.id]
    )
    |> Repo.all()
  end

  defp filter_query(query, "current", now),
    do: where(query, [l], l.start_date <= ^now and is_nil(l.actual_move_out))

  defp filter_query(query, "past", now),
    do: where(query, [l], l.actual_move_out > ^now and not is_nil(l.actual_move_out))

  defp filter_query(query, "future", now), do: where(query, [l], l.start_date > ^now)
end
