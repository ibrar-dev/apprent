defmodule AppCount.Reports.GrossPotentialRent do
  import Ecto.Query
  import AppCount.EctoExtensions
  import AppCount.Reports.Queries.Vacancy
  import AppCount.Reports.Queries.MarketRent
  alias AppCount.Accounting.Receipt
  alias AppCount.Repo
  alias AppCount.Ledgers
  alias AppCount.Accounting
  alias AppCount.Properties.Unit
  alias AppCount.Tenants.Tenant
  use AppCount.Decimal

  def run(property_id, date_string, post_month) do
    date = Date.from_iso8601!(date_string)

    rent_account_ids = [
      Accounting.SpecialAccounts.get_account(:rent).id,
      Accounting.SpecialAccounts.get_account(:hap_rent).id
    ]

    vacancy_month = Date.from_iso8601!(post_month)
    #    days_in_month = Timex.days_in_month(vacancy_month)

    tenants =
      from(
        tenant in Tenant,
        join: tenancy in assoc(tenant, :tenancies),
        select: %{
          tenancy_id: tenancy.id,
          tenant: jsonize_one(tenant, [:id, :first_name, :last_name])
        },
        where: is_nil(tenancy.actual_move_out) and tenancy.start_date <= ^date,
        group_by: tenancy.id
      )

    from(
      u in Unit,
      left_join: tenancy in assoc(u, :tenancy),
      left_join: t in subquery(tenants),
      on: t.tenancy_id == tenancy.id,
      left_join: b in subquery(delinquency_query(property_id, date, rent_account_ids)),
      on: b.ledger_id == tenancy.customer_ledger_id,
      left_join:
        v in subquery(
          vacancy_query(property_id, vacancy_month, Timex.end_of_month(vacancy_month))
        ),
      on: v.unit_id == u.id,
      left_join: mr in subquery(market_rent_query(property_id, date)),
      on: mr.unit_id == u.id,
      left_join: receipts in subquery(receipts_query(property_id, post_month, rent_account_ids)),
      on: tenancy.customer_ledger_id in receipts.ledger_id,
      left_join:
        balance in subquery(balance_query(property_id, Timex.shift(vacancy_month, days: -1))),
      on: balance.ledger_id == tenancy.customer_ledger_id,
      where: u.property_id == ^property_id,
      select: %{
        unit_id: u.id,
        status: u.status,
        start_date: tenancy.start_date,
        move_in: tenancy.actual_move_in,
        tenant: coalesce(t.tenant, "{\"first_name\": \"VACANT\"}"),
        market_rent: type(mr.market_rent, :float),
        floor_plan: mr.floor_plan,
        number: u.number,
        #        rent:
        #          case_when(
        #            is_nil(t.tenant),
        #            type(mr.market_rent, :float),
        #            type(sum(l.rent), :float)
        #          ),
        #        actual_rent:
        #          fragment(
        #            "round(CAST(? AS numeric), 2)::float",
        #            (^days_in_month - v.days_vacant) / type(^days_in_month, :float) * sum(l.rent)
        #          ),
        #        concession:
        #          type(sum(l.concessions), :float) *
        #            ((^days_in_month - v.days_vacant) / type(^days_in_month, :float)),
        receipts_current: coalesce(type(receipts.current, :float), 0),
        receipts_prior: coalesce(type(receipts.prior, :float), 0),
        delinquency: coalesce(type(sum(b.unpaid), :float), 0),
        balance: fragment("LEAST(?, 0)", type(balance.balance, :float))
      },
      group_by: [
        u.id,
        #        l.current,
        #        l.move_in,
        #        l.section_8,
        #        l.in_effect,
        #        l.start_date,
        tenancy.id,
        v.days_vacant,
        t.tenant,
        receipts.current,
        receipts.prior,
        mr.market_rent,
        mr.floor_plan,
        balance.balance
      ],
      order_by: [
        asc:
          fragment(
            "CASE WHEN ? = 'DOWN' THEN 1 WHEN ? IS NOT NULL THEN 2 ELSE 0 END",
            u.status,
            tenancy.start_date
          ),
        asc: u.number
      ]
    )
    |> Repo.all()
    |> add_total_rows
  end

  def add_total_rows(data) do
    {last_group, final, totals, group_index} =
      Enum.reduce(
        data,
        {[], [], [], 0},
        fn row, {current_group, final, totals, group_index} ->
          cond do
            row.status == "DOWN" and group_index == 0 ->
              total = get_total_row(current_group, "main", "down")
              {[row], current_group ++ [total], [total], 1}

            !is_nil(row.move_in) and group_index < 2 ->
              total =
                get_total_row(current_group, Enum.at(["main", "down"], group_index), "future")

              {[row], final ++ current_group ++ [total], totals ++ [total], 2}

            true ->
              {current_group ++ [row], final, totals, group_index}
          end
        end
      )

    last_total =
      get_total_row(last_group, Enum.at(["main", "down", "future"], group_index), "final")

    final ++ last_group ++ [last_total] ++ [get_total_row(totals ++ [last_total], "final", nil)]
  end

  def get_total_row(data, type, next_group) do
    Enum.reduce(
      data,
      get_total_fields(type),
      fn row, totals ->
        Enum.into(
          totals,
          %{},
          fn {field, running_total} ->
            {field, running_total + row[field]}
          end
        )
      end
    )
    |> Map.merge(%{total: true, type: type, next_group: next_group})
  end

  def delinquency_query(property_id, date, rent_account_ids) do
    from(
      c in Ledgers.Charge,
      join: ledger in assoc(c, :customer_ledger),
      left_join: r in assoc(c, :receipts),
      on: r.charge_id == c.id,
      on: is_nil(r.stop_date) or r.stop_date > ^date,
      on: is_nil(r.start_date) or r.start_date <= ^date,
      left_join: p in assoc(r, :payment),
      on: r.payment_id == p.id,
      on: type(p.inserted_at, :date) <= ^date,
      left_join: con in assoc(r, :concession),
      on: r.concession_id == con.id,
      on: con.bill_date <= ^date,
      where: c.account_id in ^rent_account_ids,
      where: is_nil(c.reversal_id),
      where: ledger.property_id == ^property_id,
      where: c.amount > 0,
      select: %{
        ledger_id: c.customer_ledger_id,
        unpaid: c.amount - coalesce(sum(r.amount), 0)
      },
      group_by: [c.id]
    )
  end

  defp receipts_query(property_id, post_month, rent_account_ids) do
    from(
      r in Receipt,
      join: p in assoc(r, :payment),
      join: c in assoc(r, :charge),
      join: l in assoc(c, :customer_ledger),
      where: p.post_month == ^post_month or c.post_month == ^post_month,
      where: c.account_id in ^rent_account_ids,
      where: l.property_id == ^property_id,
      select: %{
        ledger_id: l.id,
        current:
          sum(r.amount)
          |> filter(p.post_month == c.post_month),
        prior:
          sum(r.amount)
          |> filter(p.post_month < c.post_month)
      },
      group_by: l.id
    )
  end

  def balance_query(property_id, date) do
    AppCount.Ledgers.CustomerLedgerRepo.ledger_balances_query(date)
    |> where([ledger], ledger.property_id == ^property_id)
    |> select(
      [ledger, payment, charge],
      %{ledger_id: ledger.id, balance: coalesce(charge.sum, 0) - coalesce(payment.sum, 0)}
    )
  end

  defp get_total_fields("down"), do: %{number: 6_500_000_000, market_rent: 0}

  defp get_total_fields(_type) do
    %{
      number: 6_500_000_000,
      market_rent: 0,
      rent: 0,
      actual_rent: 0,
      concession: 0,
      receipts_current: 0,
      receipts_prior: 0,
      delinquency: 0,
      balance: 0
    }
  end
end
