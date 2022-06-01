defmodule AppCount.Reports.AgingReport do
  import Ecto.Query
  alias AppCount.Repo
  alias AppCount.Admins
  alias AppCount.Accounting.Invoicing
  alias AppCount.Ledgers.Charge
  alias AppCount.Accounting.Receipt
  alias AppCount.Ledgers.Payment
  alias AppCount.Leases.Lease
  import AppCount.EctoExtensions
  alias AppCount.Core.ClientSchema

  def aging_report(admin, property_id, date \\ nil) do
    # TODO:SCHEMA remove dasmen
    if Admins.has_permission?(ClientSchema.new("dasmen", admin), property_id) do
      unresolved_leases(property_id, date) ++ unpaid_invoices(property_id, date)
    end
  end

  def unpaid_invoices(property_id, date) do
    today = if date, do: Date.from_iso8601!(date), else: AppCount.current_date()

    sub =
      from(
        i in Invoicing,
        where: i.property_id == ^property_id,
        left_join: p in assoc(i, :payments),
        join: a in assoc(i, :account),
        join: invoice in assoc(i, :invoice),
        join: payee in assoc(invoice, :payee),
        where: invoice.date <= ^today,
        select: %{
          id: i.id,
          invoice_id: invoice.id,
          account: a.name,
          date: invoice.date,
          notes: invoice.notes,
          inv_notes: i.notes,
          number: invoice.number,
          payee: payee.name,
          payee_id: payee.id,
          amount: i.amount - sum(coalesce(p.amount, 0)),
          days_late: ^today - invoice.due_date
        },
        group_by: [i.id, a.id, invoice.id, payee.id]
      )

    from(
      i in subquery(sub),
      select: %{
        invoices:
          jsonize(i, [
            :id,
            :account,
            :date,
            :number,
            :inv_notes,
            :notes,
            :amount,
            :invoice_id,
            :days_late
          ]),
        payee: i.payee,
        id: i.payee_id
      },
      where: i.amount > 0,
      group_by: [i.payee, i.payee_id]
    )
    |> Repo.all()
  end

  def unresolved_leases(property_id, date) do
    today = if date, do: Date.from_iso8601!(date), else: AppCount.current_date()

    concessions =
      from(
        c in Charge,
        left_join: r in Receipt,
        on:
          r.concession_id == c.id and (is_nil(r.stop_date) or r.stop_date > ^today) and
            (is_nil(r.start_date) or r.start_date <= ^today),
        where: c.amount < 0,
        select: %{
          id: c.id,
          lease_id: c.lease_id,
          amount: c.amount * -1 - sum(coalesce(r.amount, 0))
        },
        group_by: c.id
      )

    concession_totals =
      from(
        l in Lease,
        left_join: c in subquery(concessions),
        on: c.lease_id == l.id,
        select: %{
          lease_id: l.id,
          amount: sum(c.amount)
        },
        group_by: l.id
      )

    excess_payments =
      from(
        p in Payment,
        left_join: r in assoc(p, :receipts),
        on:
          p.id == r.payment_id and (is_nil(r.stop_date) or r.stop_date > ^today) and
            (is_nil(r.start_date) or r.start_date <= ^today),
        where: p.status == "cleared",
        select: %{
          id: p.id,
          tenant_id: p.tenant_id,
          inserted_at: p.inserted_at,
          amount: p.amount - sum(coalesce(r.amount, 0))
        },
        group_by: p.id
      )

    payments =
      from(
        l in Lease,
        join: u in assoc(l, :unit),
        join: t in assoc(l, :tenants),
        left_join: p in subquery(excess_payments),
        on: p.tenant_id == t.id,
        where: p.inserted_at < l.actual_move_out,
        where: p.inserted_at > l.start_date,
        where: p.amount > 0,
        where: u.property_id == ^property_id,
        group_by: l.id,
        select: %{
          lease_id: l.id,
          amount: sum(p.amount)
        }
      )

    from(
      l in Lease,
      join: u in assoc(l, :unit),
      join: t in assoc(l, :tenants),
      left_join: p in subquery(payments),
      on: p.lease_id == l.id,
      left_join: c in subquery(concession_totals),
      on: c.lease_id == l.id,
      where: c.amount > 0 or p.amount > 0,
      where: u.property_id == ^property_id,
      where: not is_nil(l.actual_move_out),
      where: l.actual_move_out <= ^today,
      select: %{
        payee: array(fragment("? || ' ' || ?", t.first_name, t.last_name)),
        invoices: [
          %{
            id: l.id,
            account: "",
            date: l.actual_move_out,
            number: "",
            notes: "Move out refund",
            invoice_id: l.id,
            days_late: ^today - l.actual_move_out,
            amount: coalesce(p.amount, 0) + coalesce(c.amount, 0)
          }
        ],
        id: max(t.id),
        amount: coalesce(p.amount, 0) + coalesce(c.amount, 0)
      },
      group_by: [l.id, c.amount, p.amount]
    )
    |> Repo.all()
  end
end
