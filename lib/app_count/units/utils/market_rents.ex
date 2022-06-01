defmodule AppCount.Units.Utils.MarketRents do
  import Ecto.Query
  alias AppCount.Repo
  alias AppCount.Properties.Unit
  alias AppCount.Core.ClientSchema

  def market_rent(%ClientSchema{
        name: client_schema,
        attrs: unit_id
      }) do
    floor_plan_price =
      from(
        u in Unit,
        left_join: plan in assoc(u, :floor_plan),
        left_join: fp in assoc(plan, :features),
        where: is_nil(fp.stop_date),
        where: u.id == ^unit_id,
        select: %{
          id: u.id,
          price: sum(coalesce(fp.price, 0))
        },
        group_by: u.id
      )

    features_price =
      from(
        u in Unit,
        left_join: f in assoc(u, :features),
        where: is_nil(f.stop_date),
        where: u.id == ^unit_id,
        select: %{
          id: u.id,
          price: sum(coalesce(f.price, 0))
        },
        group_by: u.id
      )

    from(
      u in Unit,
      left_join: f in subquery(features_price),
      on: f.id == u.id,
      left_join: plan in subquery(floor_plan_price),
      on: plan.id == u.id,
      join: p in assoc(u, :property),
      join: s in assoc(p, :setting),
      where: u.id == ^unit_id,
      select: type(u.area * s.area_rate + plan.price + f.price, :float)
    )
    |> Repo.one(prefix: client_schema)
  end
end
