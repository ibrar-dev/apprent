defmodule AppCount.Reports.Queries.MarketRent do
  import Ecto.Query
  alias AppCount.Properties.Unit
  alias AppCount.Properties.Charge
  alias AppCount.Accounting

  def market_rent_query(property_id, date) do
    fp_query =
      from(
        u in Unit,
        join: fp in assoc(u, :floor_plan),
        join: f in assoc(fp, :features),
        where: u.property_id == ^property_id,
        where: is_nil(f.stop_date) or f.stop_date >= ^date,
        where: is_nil(f.start_date) or f.start_date <= ^date,
        select: %{
          id: u.id,
          floor_plan: fp.name,
          price: sum(f.price)
        },
        group_by: [u.id, fp.id]
      )

    feature_query =
      from(
        u in Unit,
        join: f in assoc(u, :features),
        where: u.property_id == ^property_id,
        where: is_nil(f.stop_date) or f.stop_date >= ^date,
        where: is_nil(f.start_date) or f.start_date <= ^date,
        select: %{
          id: u.id,
          floor_plan: "",
          price: sum(f.price)
        },
        group_by: u.id
      )
      |> union_all(^fp_query)
      |> subquery()
      |> select([u], %{id: u.id, floor_plan: max(u.floor_plan), price: sum(u.price)})
      |> group_by([u], u.id)

    from(
      u in Unit,
      join: p in assoc(u, :property),
      join: s in assoc(p, :setting),
      left_join: f in subquery(feature_query),
      on: f.id == u.id,
      where: u.property_id == ^property_id,
      select: %{
        unit_id: u.id,
        property_id: u.property_id,
        market_rent: f.price + s.area_rate * u.area,
        number: u.number,
        floor_plan: f.floor_plan,
        area: u.area,
        area_rate: s.area_rate,
        area_charge: s.area_rate * u.area
      }
    )
  end

  def rent_charge_query(date) do
    rent_code = Accounting.SpecialAccounts.get_charge_code(:rent)
    haprent_code = Accounting.SpecialAccounts.get_charge_code(:hap_rent)

    from(
      c in Charge,
      #      where: (c.from_date <= ^date and is_nil(c.to_date)) or (is_nil(c.from_date) and c.to_date >= ^date) or (
      #        is_nil(c.from_date) and is_nil(c.to_date)) or (c.from_date <= ^date and c.to_date >= ^date),
      where:
        (c.from_date <= ^date or is_nil(c.from_date)) and
          (c.to_date >= ^date or is_nil(c.to_date)),
      join: ch in assoc(c, :charge_code),
      join: a in assoc(ch, :account),
      where: c.charge_code_id == ^rent_code.id or c.charge_code_id == ^haprent_code.id,
      select: %{
        id: c.id,
        amount: c.amount,
        lease_id: c.lease_id,
        name: a.name
      }
    )
  end
end
