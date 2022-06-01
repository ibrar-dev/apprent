defmodule AppCount.Accounting.Ledger.Invoices do
  import Ecto.Query
  alias AppCount.Accounting.Invoicing
  alias AppCount.Accounting.InvoicePayment

  def invoicings(property_id) do
    from(
      i in Invoicing,
      join: inv in assoc(i, :invoice),
      join: p in assoc(inv, :payee),
      where: i.property_id == ^property_id,
      select: %{
        id: fragment("'invoicing-' || ?", i.id),
        date: inv.date,
        post_month: inv.post_month,
        desc: fragment("'Invoice #' || ? || ' from ' || ?", inv.number, p.name),
        debit_account_id:
          fragment(
            "CASE WHEN ? > 0 THEN ? ELSE ? END",
            i.amount,
            i.account_id,
            inv.payable_account_id
          ),
        credit_account_id:
          fragment(
            "CASE WHEN ? > 0 THEN ? ELSE ? END",
            i.amount,
            inv.payable_account_id,
            i.account_id
          ),
        amount: fragment("ABS(?)", i.amount),
        ref: inv.id,
        source: "invoices"
      }
    )
  end

  # yes, lots of duplicate code here. It's Ecto's fault :( :(
  def invoice_payments(property_id, "accrual") do
    from(
      p in InvoicePayment,
      join: i in assoc(p, :invoicing),
      join: inv in assoc(i, :invoice),
      join: payee in assoc(inv, :payee),
      where: i.property_id == ^property_id,
      select: %{
        id: fragment("'invoice_payment-' || ?", p.id),
        date: type(p.inserted_at, :date),
        post_month: p.post_month,
        desc: fragment("'Invoice #' || ? || ' from ' || ?", inv.number, payee.name),
        debit_account_id:
          fragment(
            "CASE WHEN ? > 0 THEN ? ELSE ? END",
            i.amount,
            inv.payable_account_id,
            p.account_id
          ),
        credit_account_id:
          fragment(
            "CASE WHEN ? > 0 THEN ? ELSE ? END",
            i.amount,
            p.account_id,
            inv.payable_account_id
          ),
        amount: fragment("ABS(?)", p.amount),
        ref: inv.id,
        source: "invoices"
      }
    )
  end

  def invoice_payments(property_id, "cash") do
    from(
      p in InvoicePayment,
      join: i in assoc(p, :invoicing),
      join: inv in assoc(i, :invoice),
      join: payee in assoc(inv, :payee),
      where: i.property_id == ^property_id,
      select: %{
        id: fragment("'invoice_payment-' || ?", p.id),
        date: type(p.inserted_at, :date),
        post_month: p.post_month,
        desc: fragment("'Invoice #' || ? || ' from ' || ?", inv.number, payee.name),
        debit_account_id:
          fragment("CASE WHEN ? > 0 THEN ? ELSE ? END", i.amount, i.account_id, p.account_id),
        credit_account_id:
          fragment("CASE WHEN ? > 0 THEN ? ELSE ? END", i.amount, p.account_id, i.account_id),
        amount: fragment("ABS(?)", p.amount),
        ref: inv.id,
        source: "invoices"
      }
    )
  end
end
