defmodule AppCount.Reports.Property.EffectiveRent do
  import Ecto.Query
  import AppCount.Reports.Queries.MarketRent
  import AppCount.EctoExtensions
  alias AppCount.Accounting
  alias AppCount.Accounting.Repo
  alias AppCount.Leases.Lease
  alias AppCount.Repo

  def run(property_id, date, unit_id \\ nil) do
    property_id
    |> query(date, unit_id)
    |> Repo.all()
  end

  defp query(property_id, date, nil) do
    rent_accounts = [
      Accounting.SpecialAccounts.get_account(:rent).id,
      Accounting.SpecialAccounts.get_account(:hap_rent).id
    ]

    from(
      u in subquery(market_rent_query(property_id, date)),
      left_join: l in Lease,
      on: l.unit_id == u.unit_id,
      on: l.start_date <= ^date,
      on: is_nil(l.actual_move_out) or l.actual_move_out > ^date,
      left_join: c in assoc(l, :charges),
      on: c.lease_id == l.id,
      on: c.account_id in ^rent_accounts,
      left_join: rc in assoc(l, :bills),
      on: rc.lease_id == l.id,
      on: rc.account_id in ^rent_accounts,
      on: rc.amount > 0,
      left_join: b in assoc(l, :bills),
      on: b.lease_id == l.id,
      on: b.amount < 0,
      left_join: t in assoc(l, :tenants),
      where: u.property_id == ^property_id,
      select: %{
        unit_id: u.unit_id,
        market_rent: u.market_rent,
        number: u.number,
        floor_plan: u.floor_plan,
        area: u.area,
        tenants: jsonize(t, [:id, :first_name, :last_name]),
        rent_amount: jsonize(c, [:id, :amount, :from_date, :to_date]),
        rent_charges: jsonize(rc, [:id, :amount, :bill_date]),
        concessions: jsonize(b, [:id, :amount, :bill_date]),
        lease_start: l.start_date,
        lease_end: l.end_date
      },
      group_by: [
        u.unit_id,
        u.floor_plan,
        u.market_rent,
        u.number,
        u.area,
        l.start_date,
        l.end_date
      ]
    )
  end

  defp query(property_id, date, unit_id) do
    property_id
    |> query(date, nil)
    |> where([u], u.unit_id == ^unit_id)
  end
end
