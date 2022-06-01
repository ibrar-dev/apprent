defmodule AppCount.Accounting.Ledger do
  import Ecto.Query
  import AppCount.Accounting.Ledger.Payments
  import AppCount.Accounting.Ledger.Invoices
  import AppCount.Accounting.Ledger.NSF
  import AppCount.Accounting.Ledger.Charges
  alias AppCount.Repo
  alias AppCount.Accounting.JournalEntry
  alias AppCount.Accounting.Check
  alias AppCount.Accounting.Register
  @far_future %Date{year: 2500, month: 1, day: 1}

  def general_ledger(property_id, book, date \\ @far_future) do
    property_id
    |> general_ledger_query(book, date)
    |> Repo.all()
  end

  def general_ledger_query(property_ids, book, date \\ @far_future)

  def general_ledger_query([first_id | rest], book, date) do
    base = from(first in subquery(general_ledger_query(first_id, book, date)))

    rest
    |> Enum.reduce(
      base,
      fn id, q ->
        q
        |> union(^general_ledger_query(id, book, date))
      end
    )
  end

  def general_ledger_query(property_id, book, date) do
    default = default_accounts(property_id)

    q =
      from(
        entries in subquery(invoice_payments(property_id, book)),
        union: ^subquery(lease_concessions(property_id, default, book, date)),
        union: ^subquery(tenant_payments(property_id, default, book, date)),
        union: ^subquery(prepaid_payment_debits(property_id, default, book, date)),
        union: ^subquery(prepaid_tenant_payments(property_id, default, book, date)),
        union: ^subquery(non_tenant_payments(property_id, default)),
        union: ^subquery(application_payments(property_id, default)),
        union: ^subquery(non_tenant_payment_refunds(property_id, default)),
        #          union: ^subquery(payment_nsfs(property_id, default, book)),
        union: ^subquery(journal_entries(property_id, book)),
        union: ^subquery(tenant_checks(property_id))
      )
      |> accrual_entries(property_id, default, book)

    from(
      e in subquery(q),
      order_by: [
        asc: e.date
      ]
    )
  end

  def accrual_entries(query, property_id, default, "accrual") do
    query
    |> union(^invoicings(property_id))
    |> union(^lease_charges(property_id, default))
  end

  def accrual_entries(query, _, _, "cash"), do: query

  def itemized_ledger_query(property_id, book, date \\ @far_future) do
    from(
      q in subquery(general_ledger_query(property_id, book, date)),
      inner_lateral_join:
        b in fragment(
          "(VALUES (?, ?, 'credit'), (?, ?, 'debit'))",
          q.id,
          q.credit_account_id,
          q.id,
          q.debit_account_id
        ),
      on: b.column1 == q.id,
      select: %{
        id: b.column1,
        date: q.date,
        post_month: q.post_month,
        desc: q.desc,
        account_id: b.column2,
        type: b.column3,
        amount: q.amount,
        ref: q.ref,
        source: q.source
      }
    )
  end

  def default_accounts(property_id) do
    from(
      r in Register,
      where: r.property_id == ^property_id,
      where: r.is_default == true,
      select: %{
        account_id: r.account_id,
        type: r.type
      }
    )
    |> Repo.all()
    |> Enum.into(%{}, fn %{type: type, account_id: account_id} -> {type, account_id} end)
  end

  def journal_entries(property_id, book) do
    book = String.to_atom(book)

    from(
      j in JournalEntry,
      join: p in assoc(j, :page),
      where: j.property_id == ^property_id,
      where: field(p, ^book) == true,
      select: %{
        id: fragment("'journal_entry-' || ?", j.id),
        date: p.date,
        post_month: p.post_month,
        desc: fragment("'Journal Entry: ' || ? ", p.name),
        debit_account_id:
          fragment("CASE WHEN ? = 't' THEN NULL ELSE ? END", j.is_credit, j.account_id),
        credit_account_id:
          fragment("CASE WHEN ? = 't' THEN ? ELSE NULL END", j.is_credit, j.account_id),
        amount: j.amount,
        ref: p.id,
        source: "journal_entries"
      }
    )
  end

  def tenant_checks(property_id) do
    from(
      c in Check,
      join: charge in assoc(c, :charge),
      join: charge_code in assoc(charge, :charge_code),
      join: t in assoc(c, :tenant),
      join: l in assoc(c, :lease),
      join: u in assoc(l, :unit),
      join: ba in assoc(c, :bank_account),
      where: u.property_id == ^property_id,
      select: %{
        id: fragment("'charge-' || ?", charge.id),
        date: c.date,
        post_month: charge.post_month,
        desc:
          fragment(
            "'Check to Tenant ' || ? || ' ' || ? || '(Unit ' || ? || ')'",
            t.first_name,
            t.last_name,
            u.number
          ),
        debit_account_id: charge_code.account_id,
        credit_account_id: ba.account_id,
        amount: charge.amount,
        ref: c.tenant_id,
        source: "tenants"
      }
    )
  end
end
