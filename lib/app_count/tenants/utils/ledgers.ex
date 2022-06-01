defmodule AppCount.Tenants.Utils.Ledgers do
  alias AppCount.Tenants.Tenant
  alias AppCount.Ledgers.Charge
  alias AppCount.Ledgers.Payment
  import Ecto.Query
  import AppCount.EctoExtensions

  ## Pass in any combination of property_id: property_id, tenant_id: tenant_id or unit_id: unit_id
  ## To use the built in where clauses.
  ## For custom clauses such as dates pipe it into a where clause
  ## ledger_query(property_id: 154, tenant_id: 123456, unit_id: 666)
  ## |> where([c], c.date <= ^date)
  ## |> etc etc

  def ledger_query(opts \\ []) do
    ledgers =
      from(
        c in subquery(itemized_charge_query(opts)),
        union: ^subquery(itemized_payment_query(opts)),
        select: %{
          id: c.id,
          date: c.date,
          post_month: c.post_month,
          tenant_id: c.tenant_id,
          unit_id: c.unit_id,
          property_id: c.property_id,
          amount: c.amount,
          account: c.account,
          type: c.type,
          admin: c.admin,
          notes: c.notes,
          transaction: c.transaction,
          lease_id: c.lease_id
        }
      )

    from(
      s in subquery(ledgers),
      select: %{
        id: s.id,
        date: s.date,
        post_month: s.post_month,
        tenant_id: s.tenant_id,
        unit_id: s.unit_id,
        property_id: s.property_id,
        amount: type(s.amount, :float),
        decimal: type(s.amount, :decimal),
        account: s.account,
        type: s.type,
        admin: s.admin,
        notes: s.notes,
        lease_id: s.lease_id,
        transaction: s.transaction,
        balance:
          sum(
            fragment(
              "CASE WHEN ? = 'charge' THEN ? ELSE (CASE WHEN ? != ? THEN ? * -1 ELSE 0 END) END",
              s.type,
              s.amount,
              s.notes,
              "voided",
              s.amount
            )
          )
          |> over(
            partition_by: [s.unit_id, s.tenant_id],
            order_by: [
              asc: s.date,
              asc: s.id,
              asc: s.type
            ]
          )
      },
      order_by: [
        asc: s.date
      ]
    )
    |> where_clauses(Keyword.drop(opts, [:exclude_nsf]))
  end

  def balance_query(opts \\ []) do
    from(
      c in subquery(charge_query()),
      left_join: p in subquery(payment_query()),
      on: p.tenant_id == c.tenant_id and p.unit_id == c.unit_id,
      select: %{
        balance: coalesce(c.amount, 0) - coalesce(p.amount, 0),
        tenant_id: c.tenant_id,
        unit_id: c.unit_id,
        property_id: c.property_id
      }
    )
    |> where_clauses(Keyword.drop(opts, [:exclude_nsf]))
  end

  defp where_clauses(query, []), do: query

  defp where_clauses(query, [{:date, [gt: date]} | opts]) do
    query
    |> where([c], field(c, :date) >= ^date)
    |> where_clauses(opts)
  end

  defp where_clauses(query, [{:date, [lt: date]} | opts]) do
    query
    |> where([c], field(c, :date) <= ^date)
    |> where_clauses(opts)
  end

  defp where_clauses(query, [{column, value} | opts]) do
    query
    |> where([c], field(c, ^column) == ^value)
    |> where_clauses(opts)
  end

  defp itemized_charge_query(opts) do
    from(
      l in subquery(ledger_lease_ids()),
      left_join: c in Charge,
      on: c.lease_id in l.lease_ids,
      left_join: cc in assoc(c, :charge_code),
      left_join: a in assoc(cc, :account),
      select: %{
        id: c.id,
        date: c.bill_date,
        post_month: c.post_month,
        tenant_id: l.tenant_id,
        unit_id: l.unit_id,
        property_id: l.property_id,
        amount: c.amount,
        account: a.name,
        type: "charge",
        admin: c.admin,
        notes: c.description,
        transaction: "",
        lease_id: c.lease_id
      }
    )
    |> charge_opts(opts)
  end

  defp charge_opts(q, [{:exclude_nsf, _} | opts]) do
    q
    |> where([l, c], is_nil(c.nsf_id))
    |> charge_opts(opts)
  end

  defp charge_opts(q, [_ | opts]), do: charge_opts(q, opts)
  defp charge_opts(q, _), do: q

  defp itemized_payment_query(opts) do
    from(
      p in Payment,
      left_join: l in subquery(ledger_lease_ids()),
      on: p.lease_id in l.lease_ids,
      select: %{
        id: p.id,
        date: type(p.inserted_at, :date),
        post_month: p.post_month,
        tenant_id: l.tenant_id,
        unit_id: l.unit_id,
        property_id: l.property_id,
        amount: p.amount,
        account: p.description,
        type: "payment",
        admin: p.admin,
        notes: p.status,
        transaction: p.transaction_id,
        lease_id: p.lease_id
      }
    )
    |> payment_opts(opts)
  end

  defp payment_opts(q, [{:exclude_nsf, date} | opts]) do
    d = Timex.to_date(date)

    q
    |> join(:left, [p], nsf in assoc(p, :nsf))
    |> where([p, l, nsf], coalesce(nsf.bill_date, ^%Date{year: 2500, month: 1, day: 1}) > ^d)
    |> payment_opts(opts)
  end

  defp payment_opts(q, [_ | opts]), do: payment_opts(q, opts)
  defp payment_opts(q, _), do: q

  defp charge_query() do
    from(
      l in subquery(ledger_lease_ids()),
      left_join: c in Charge,
      on: c.lease_id in l.lease_ids,
      select: %{
        tenant_id: l.tenant_id,
        unit_id: l.unit_id,
        property_id: l.property_id,
        amount: sum(c.amount)
      },
      group_by: [l.unit_id, l.tenant_id, l.property_id]
    )
  end

  defp payment_query() do
    from(
      l in subquery(ledger_lease_ids()),
      left_join: p in Payment,
      on: p.lease_id in l.lease_ids,
      where: p.status != "voided",
      select: %{
        tenant_id: l.tenant_id,
        unit_id: l.unit_id,
        property_id: l.property_id,
        amount: sum(p.amount)
      },
      group_by: [l.unit_id, l.tenant_id, l.property_id]
    )
  end

  defp ledger_lease_ids() do
    from(
      t in Tenant,
      join: l in assoc(t, :leases),
      join: u in assoc(l, :unit),
      select: %{
        lease_ids: array(l.id),
        tenant_id: t.id,
        unit_id: u.id,
        property_id: u.property_id
      },
      group_by: [u.id, t.id]
    )
  end
end
