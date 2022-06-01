defmodule AppCount.Reports.Availability do
  import Ecto.Query
  import AppCount.Decimal
  import AppCount.EctoExtensions
  alias AppCount.Repo
  alias AppCount.Properties.Unit
  alias AppCount.Leases.Lease
  alias AppCount.RentApply.MoveIn

  defp rent_charge() do
    from(
      c in AppCount.Properties.Charge,
      where: c.account_id == 1,
      select: %{
        id: c.id,
        amount: c.amount,
        lease_id: c.lease_id
      }
    )
  end

  def market_rent() do
    from(
      u in Unit,
      left_join: f in assoc(u, :features),
      left_join: plan in assoc(u, :floor_plan),
      left_join: fp in assoc(plan, :features),
      left_join: dc in assoc(plan, :default_charges),
      left_join: cc in assoc(dc, :charge_code),
      where: is_nil(f.stop_date),
      where: is_nil(fp.stop_date),
      select: %{
        unit_id: u.id,
        base_rent: jsonize(fp, [:id, :name, :price]),
        base_feature: jsonize(f, [:id, :name, :price]),
        features: jsonize(dc, [:id, :price, :default_charge, {:name, cc.name}]),
        market_rent: coalesce(sum(f.price), 0) + coalesce(sum(fp.price), 0)
      },
      group_by: [u.id, dc.id],
      distinct: u.id
    )
  end

  def availability_report(admin, property_id) do
    renewal_ids =
      from(
        l in Lease,
        select: l.renewal_id,
        where: not is_nil(l.renewal_id)
      )
      |> Repo.all()

    applicant_move_ins =
      from(
        m in MoveIn,
        join: u in assoc(m, :unit),
        select: %{
          id: m.id,
          expected_move_in: m.expected_move_in,
          application_id: m.application_id,
          unit_id: m.unit_id,
          floor_plan_id: m.floor_plan_id
        }
      )

    lease_query =
      from(
        l in Lease,
        left_join: ten in assoc(l, :tenants),
        left_join: card in assoc(l, :card),
        left_join: cI in assoc(card, :items),
        left_join: c in subquery(rent_charge()),
        on: c.lease_id == l.id,
        left_join: m in subquery(applicant_move_ins),
        on: m.unit_id == l.unit_id,
        select:
          map(l, [
            :id,
            :start_date,
            :end_date,
            :move_out_date,
            :expected_move_in,
            :actual_move_in,
            :inserted_at
          ]),
        select_merge:
          map(l, [:unit_id, :renewal_id, :notice_date, :deposit_amount, :actual_move_out]),
        select_merge: %{
          is_renewal: l.id in ^renewal_ids,
          amount: c.amount,
          tenant_id: ten.id
        },
        select_merge: %{
          move_in: jsonize(m, [:id, :expected_move_in, :application_id, :unit_id, :floor_plan_id])
        },
        select_merge: map(ten, [:first_name, :last_name]),
        select_merge: map(cI, [:completed_by, :completed]),
        distinct: [l.unit_id],
        order_by: [
          desc: l.inserted_at
        ],
        group_by: [l.id, ten.id, card.id, cI.id, c.id, m.id, c.amount]
      )

    from(
      u in Unit,
      join: p in assoc(u, :property),
      left_join: l in subquery(lease_query),
      on: l.unit_id == u.id,
      left_join: mr in subquery(market_rent()),
      on: u.id == mr.unit_id,
      left_join: f in assoc(u, :floor_plan),
      select: map(u, [:id, :number, :area, :floor_plan_id, :status, :address]),
      select_merge: %{
        property_id: p.id,
        property_name: p.name,
        floor_plan_name: f.name,
        lease:
          fragment(
            "coalesce((array_agg(row_to_json(?)) FILTER (WHERE ? IS NULL AND ? IS NULL))[1], '{}'::json)",
            l,
            l.renewal_id,
            l.actual_move_out
          ),
        prev_lease:
          fragment(
            "coalesce((array_agg(row_to_json(?)) FILTER (WHERE ? IS NOT NULL OR ? IS NOT NULL))[1], '{}'::json)",
            l,
            l.renewal_id,
            l.actual_move_out
          )
      },
      select_merge: %{market_rent: mr},
      group_by: [
        u.id,
        p.id,
        f.id,
        mr.unit_id,
        mr.features,
        mr.market_rent,
        mr.base_rent,
        mr.base_feature
      ],
      where: u.property_id in ^admin.property_ids,
      where: u.property_id == ^property_id
    )
    |> Repo.all()
  end

  def floor_plan(admin, property_id) do
    from(
      u in Unit,
      left_join: p in assoc(u, :property),
      on: u.property_id == p.id,
      left_join: f in assoc(u, :floor_plan),
      on: f.id == u.floor_plan_id,
      select: %{
        id: u.id,
        property_id: p.id,
        property_name: p.name,
        floor_plan_id: f.id,
        floor_plan_name: f.name
      },
      where: u.property_id in ^admin.property_ids,
      where: u.property_id == ^property_id
    )
    |> Repo.all()
  end
end
