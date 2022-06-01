defmodule AppCount.Reports.MonthToMonth do
  import Ecto.Query
  import AppCount.EctoExtensions

  alias AppCount.Repo
  alias AppCount.Leases.Lease
  alias AppCount.Ledgers.Charge

  def mtm_report(admin, property_id) do
    today =
      AppCount.current_time()
      |> Timex.beginning_of_day()

    bills_query =
      from(
        c in Charge,
        join: cc in assoc(c, :charge_code),
        select: %{
          id: c.id,
          charge_code: cc.name,
          amount: c.amount,
          lease_id: c.lease_id,
          bill_date: c.bill_date
        },
        where: is_nil(c.reversal_id),
        order_by: :bill_date
      )

    from(
      l in Lease,
      join: u in assoc(l, :unit),
      join: t in assoc(l, :tenants),
      join: c in assoc(l, :charges),
      join: cc in assoc(c, :charge_code),
      left_join: b in subquery(bills_query),
      on: b.lease_id == l.id,
      where: l.end_date < ^today and is_nil(l.actual_move_out) and is_nil(l.renewal_id),
      where: u.property_id == ^property_id and u.property_id in ^admin.property_ids,
      select: %{
        id: l.id,
        residents: jsonize(t, [:id, :first_name, :last_name]),
        unit: u.number,
        end_date: l.end_date,
        actual_move_out: l.actual_move_out,
        bills: jsonize(c, [:id, :amount, {:name, cc.name}, :charge_code_id]),
        recent_charges: jsonize(b, [:id, :charge_code, :amount, :bill_date])
      },
      order_by: u.number,
      group_by: [l.id, u.id]
    )
    |> Repo.all(prefix: admin.client_schema)
  end
end
