# currently deprecated and unused, it's being kept around commented out in order to port to the new leasing system

# defmodule AppCount.Tasks.Workers.LateFees do
#  import Ecto.Query
#  alias AppCount.Repo
#  alias AppCount.Leases.Lease
#  alias AppCount.Accounting
#  alias AppCount.Ledgers
#  alias AppCount.Ledgers.Utils.Charges
#  alias AppCount.Properties.Charge
#  alias AppCount.Properties.Settings
#  use AppCount.Decimal
#  use AppCount.Tasks.Worker, "Calculate late fees"
#
#  @impl AppCount.Tasks.Worker
#  def perform() do
#    from(
#      p in AppCount.Properties.Property,
#      select: p.id
#    )
#    |> Repo.all()
#    |> Enum.map(fn id -> perform([id]) end)
#  end
#
#  def perform([property_id]) do
#    settings = Settings.fetch_by_property_id(property_id)
#
#    if AppCount.current_date().day > settings.grace_period do
#      cd =
#        AppCount.current_time()
#        |> Timex.end_of_day()
#
#      month_start = Timex.beginning_of_month(cd)
#
#      balance_query =
#        AppCount.Tenants.ledger_query(
#          property_id: property_id,
#          date: [
#            lt: cd
#          ]
#        )
#        |> subquery
#        |> select(
#          [b],
#          %{
#            lease_id:
#              first_value(b.lease_id)
#              |> over(
#                partition_by: [b.tenant_id, b.unit_id],
#                order_by: [
#                  desc: b.date
#                ]
#              ),
#            account:
#              first_value(b.account)
#              |> over(
#                partition_by: [
#                  b.tenant_id,
#                  b.unit_id,
#                  b.account == "Late Fees",
#                  b.amount > 0.0
#                ],
#                order_by: [
#                  desc: b.date
#                ]
#              ),
#            amount:
#              first_value(b.amount)
#              |> over(
#                partition_by: [
#                  b.tenant_id,
#                  b.unit_id,
#                  b.account == "Late Fees",
#                  b.amount > 0.0
#                ],
#                order_by: [
#                  desc: b.date
#                ]
#              ),
#            date:
#              first_value(b.date)
#              |> over(
#                partition_by: [
#                  b.tenant_id,
#                  b.unit_id,
#                  b.account == "Late Fees",
#                  b.amount > 0.0
#                ],
#                order_by: [
#                  desc: b.date
#                ]
#              ),
#            balance:
#              first_value(b.balance)
#              |> over(
#                partition_by: [b.tenant_id, b.unit_id],
#                order_by: [
#                  desc: b.date,
#                  desc: b.id,
#                  desc: b.type
#                ]
#              )
#          }
#        )
#
#      rent_code = Accounting.SpecialAccounts.get_charge_code(:rent).id
#      haprent_code = Accounting.SpecialAccounts.get_charge_code(:hap_rent).id
#
#      from(
#        b in subquery(balance_query),
#        join: l in Lease,
#        on: l.id == b.lease_id,
#        left_join: r in assoc(l, :renewal),
#        left_join: c in Charge,
#        on:
#          l.id == c.lease_id and c.charge_code_id == ^rent_code and
#            (is_nil(c.to_date) or c.to_date >= ^month_start) and
#            (is_nil(c.from_date) or c.from_date <= ^month_start),
#        left_join: hc in Charge,
#        on:
#          l.id == hc.lease_id and hc.charge_code_id == ^haprent_code and
#            (is_nil(hc.to_date) or hc.to_date >= ^month_start) and
#            (is_nil(hc.from_date) or hc.from_date <= ^month_start),
#        distinct: [b.lease_id],
#        select: %{
#          lease_id: b.lease_id,
#          rent_charge: c.amount,
#          mlf:
#            fragment(
#              "CASE WHEN ? = 'Late Fees' AND ? > 0 AND ? >= ? THEN ? ELSE NULL END",
#              b.account,
#              b.amount,
#              b.date,
#              ^Timex.to_date(month_start),
#              b.amount
#            ),
#          balance: b.balance,
#          renewal_id: l.renewal_id,
#          start_date: l.start_date,
#          r_start_date: r.start_date,
#          move_out: l.actual_move_out,
#          haprent: not is_nil(hc)
#        },
#        order_by: [
#          desc: b.lease_id,
#          asc:
#            fragment("CASE WHEN ? = 'Late Fees' AND ? > 0 THEN 0 ELSE 1 END", b.account, b.amount)
#        ]
#      )
#      |> subquery
#      |> where([q], is_nil(q.renewal_id) or q.r_start_date > ^month_start)
#      |> where([q], is_nil(q.move_out))
#      |> where([q], q.balance >= ^settings.late_fee_threshold)
#      |> where([q], q.start_date <= ^month_start)
#      |> Repo.all()
#      |> Enum.each(&calculate_late_fees(&1, settings))
#    end
#  end
#
#  defp charge_additional_late_fee(%{lease_id: lease_id}, amount) do
#    today = AppCount.current_date()
#
#    from(
#      c in Ledgers.Charge,
#      where: c.lease_id == ^lease_id,
#      where: c.bill_date == ^today,
#      where: c.charge_code_id == ^late_fee_code().id,
#      select: count(c.id)
#    )
#    |> Repo.one()
#    |> case do
#      0 ->
#        %{
#          amount: amount,
#          status: "charge",
#          charge_code_id: late_fee_code().id,
#          bill_date: today,
#          lease_id: lease_id,
#          description: "Additional Late Fee"
#        }
#        |> Charges.create_charge()
#
#      _ ->
#        nil
#    end
#  end
#
#  #  defp compute_late_fee(%{type: "$", late_fee_amount: a}), do: a
#  #  defp compute_late_fee(%{type: "%", rent_amount: o, late_fee_amount: a}), do: a * o * 0.01
#
#  defp late_fee_code(), do: Accounting.SpecialAccounts.get_charge_code(:late_fees)
#
#  # First we check to see if they've already gotten a late fee this month and if
#  # they did and the daily addition is nothing, return acc
#  defp calculate_late_fees(
#         %{mlf: mlf, haprent: haprent} = unit,
#         %{daily_late_fee_addition: daily} = settings
#       ) do
#    cond do
#      haprent == true -> nil
#      not is_nil(mlf) and Decimal.cmp(daily, 0) == :eq -> nil
#      not is_nil(mlf) and Decimal.cmp(daily, 0) == :gt -> charge_additional_late_fee(unit, daily)
#      true -> apply_late_fee(unit, settings)
#    end
#  end
#
#  # Now the only units that should be hitting this are ones that need late fees
#  defp apply_late_fee(unit, %{late_fee_amount: amount, late_fee_type: type, grace_period: gp}) do
#    amount = calculate_late_fee(unit, amount, type)
#
#    target =
#      Timex.beginning_of_month(AppCount.current_time())
#      |> Timex.shift(days: gp)
#
#    %{
#      amount: amount,
#      status: "charge",
#      charge_code_id: late_fee_code().id,
#      bill_date: AppCount.current_date(),
#      metadata: %{
#        late_fee: target
#      },
#      lease_id: unit.lease_id
#    }
#    |> Charges.create_charge()
#  end
#
#  # If the late fee type is dollar always return amount
#  defp calculate_late_fee(_, amount, "$"), do: amount
#  # When it is not dollar calculate the percentage of rent based on the amount.
#  defp calculate_late_fee(%{rent_charge: rent_charge}, amount, _), do: amount * rent_charge * 0.01
# end
