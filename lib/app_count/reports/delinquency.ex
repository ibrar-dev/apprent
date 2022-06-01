defmodule AppCount.Reports.Delinquency do
  alias AppCount.Repo
  alias AppCount.Properties.Visit
  alias AppCount.Tenants.Tenant
  alias AppCount.Leases.Lease
  alias AppCount.Ledgers.Charge
  import Ecto.Query
  import AppCount.Decimal
  import AppCount.EctoExtensions
  use AppCount.Decimal

  def delinquency_report(property_id, date \\ nil) do
    ts =
      if date do
        date
        |> Date.from_iso8601!()
        |> Timex.to_datetime()
        |> Timex.end_of_day()
      else
        AppCount.current_time()
      end

    condensed =
      from(
        b in subquery(balance_query(property_id, ts)),
        join: l in subquery(lease_query(property_id, ts)),
        on: b.lease_id in l.lease_ids,
        select: %{
          tenant_id: max(b.tenant_id),
          owed: max(b.balance),
          charges:
            jsonize(b, [:id, :amount, :date, :days_late, :account, :tenant_id], b.date, "DESC"),
          tenant: l.tenant,
          unit: l.number,
          status: l.status,
          lease_id: b.lease_id
        },
        where: b.type == "charge",
        where: b.amount > ^0,
        where: b.balance > ^0,
        group_by: [b.tenant_id, b.lease_id, l.number, l.status, l.tenant]
      )

    dq_memo_query =
      from(
        m in Visit,
        where: not is_nil(m.delinquency),
        select: %{
          tenant_id: m.tenant_id,
          memos: jsonize(m, [:id, :description, :inserted_at, :admin], m.inserted_at, "DESC")
        },
        group_by: m.tenant_id
      )

    from(
      b in subquery(condensed),
      left_join: m in subquery(dq_memo_query),
      on: m.tenant_id == b.tenant_id,
      distinct: b.lease_id,
      select: %{
        tenant_id: b.tenant_id,
        owed: type(b.owed, :float),
        charges: b.charges,
        tenant: b.tenant,
        unit: b.unit,
        status: b.status,
        memos: coalesce(m.memos, "[]")
      },
      order_by: [
        asc: b.unit
      ]
    )
    |> Repo.all()
  end

  def collection_report(property_id, date \\ nil) do
    delinquency_report(property_id, date)
    |> Enum.filter(&(&1.status == "moved_out"))
  end

  def dashboard_dq(property_ids) do
    lease_payments =
      from(
        l in Lease,
        join: t in assoc(l, :tenants),
        join: u in assoc(l, :unit),
        left_join: p in assoc(t, :payments),
        where: u.property_id in ^property_ids,
        where: is_nil(p.id) or p.status != "voided",
        select: %{
          id: l.id,
          tenant_ids: array(t.id),
          amount: sum(coalesce(p.amount, 0))
        },
        order_by: [
          desc: l.start_date
        ],
        group_by: l.id
      )

    charges =
      from(
        c in Charge,
        select: %{
          id: c.lease_id,
          amount: sum(c.amount)
        },
        group_by: c.lease_id
      )

    tenant_charges =
      from(
        t in Tenant,
        join: l in assoc(t, :leases),
        join: u in assoc(l, :unit),
        join: c in subquery(charges),
        on: c.id == l.id,
        where: u.property_id in ^property_ids,
        select: %{
          id: t.id,
          amount: sum(c.amount)
        },
        group_by: t.id
      )

    from(
      t in subquery(tenant_charges),
      left_join: p in subquery(lease_payments),
      on: t.id in p.tenant_ids,
      where: t.amount > p.amount,
      distinct: t.id,
      select: {t.id, type(t.amount - p.amount, :float)}
    )
    |> Repo.all()
    |> Enum.reduce(0, fn {_, amount}, acc -> amount + acc end)
  end

  def lease_query(property_id, ts) do
    from(
      l in Lease,
      join: t in assoc(l, :tenants),
      join: u in assoc(l, :unit),
      left_join: e in assoc(l, :eviction),
      where: u.property_id == ^property_id,
      where: l.start_date <= ^ts,
      select: %{
        lease_ids: array(l.id),
        number: u.number,
        tenant_id: t.id,
        tenant: fragment("? || ' ' || ?", t.first_name, t.last_name),
        status:
          fragment(
            "CASE
                WHEN bool_and(? IS NOT NULL AND ? <= ?::TIMESTAMP::DATE) THEN 'moved_out'
                WHEN bool_or(? IS NOT NULL) THEN 'eviction'
                WHEN bool_and(? IS NOT NULL AND ? <= ?::TIMESTAMP::DATE) THEN 'notice'
                WHEN bool_or(? IS NOT NULL OR (? IS NOT NULL AND ? <= ?::TIMESTAMP::DATE)) THEN 'current'
                ELSE 'future'
              END",
            l.actual_move_out,
            l.actual_move_out,
            ^ts,
            e.id,
            l.notice_date,
            l.notice_date,
            ^ts,
            l.actual_move_in,
            l.actual_move_in,
            l.actual_move_in,
            ^ts
          )
      },
      group_by: [u.id, t.id]
    )
  end

  def balance_query(property_id, date) do
    ledger_query =
      AppCount.Tenants.ledger_query(
        property_id: property_id,
        exclude_nsf: date,
        date: [
          lt: date
        ]
      )

    from(
      b in subquery(ledger_query),
      select: %{
        id: b.id,
        tenant_id: b.tenant_id,
        date: b.date,
        days_late: ^Timex.to_date(date) - b.date,
        type: b.type,
        account: b.account,
        amount: type(b.amount, :float),
        lease_id:
          first_value(b.lease_id)
          |> over(
            partition_by: [b.tenant_id, b.unit_id],
            order_by: [
              desc: b.date,
              desc: b.id,
              desc: b.type
            ]
          ),
        balance:
          first_value(b.balance)
          |> over(
            partition_by: [b.tenant_id, b.unit_id],
            order_by: [
              desc: b.date,
              desc: b.id,
              desc: b.type
            ]
          )
      }
    )
  end
end
