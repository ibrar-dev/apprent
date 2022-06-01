defmodule AppCount.Accounting.Ledger.Payments do
  import Ecto.Query
  alias AppCount.Ledgers.Payment
  alias AppCount.Accounting.Receipt

  def tenant_payments(property_id, %{"receivable" => receivable, "cash" => cash}, "accrual", date) do
    from(
      p in Payment,
      join: r in assoc(p, :receipts),
      join: c in assoc(r, :charge),
      join: l in assoc(c, :lease),
      join: u in assoc(l, :unit),
      join: t in assoc(p, :tenant),
      where: p.property_id == ^property_id,
      where: c.bill_date < p.inserted_at,
      where: is_nil(r.stop_date) or r.stop_date > ^date,
      where: is_nil(r.start_date) or r.start_date <= ^date,
      select: %{
        id: fragment("'receipt-' || ?", r.id),
        date: type(p.inserted_at, :date),
        post_month: p.post_month,
        desc:
          fragment(
            "'Payment from tenant ' || ? || ' ' || ? || '(Unit ' || ? || ')'",
            t.first_name,
            t.last_name,
            u.number
          ),
        debit_account_id: fragment("?::bigint", ^cash),
        credit_account_id: fragment("?::bigint", ^receivable),
        amount: r.amount,
        ref: p.tenant_id,
        source: "tenants"
      }
    )
  end

  def tenant_payments(property_id, %{"cash" => cash}, "cash", date) do
    from(
      p in Payment,
      join: r in assoc(p, :receipts),
      join: c in assoc(r, :charge),
      join: cc in assoc(c, :charge_code),
      join: l in assoc(c, :lease),
      join: u in assoc(l, :unit),
      join: t in assoc(p, :tenant),
      where: p.property_id == ^property_id,
      where: c.bill_date < p.inserted_at,
      where: is_nil(r.stop_date) or r.stop_date > ^date,
      where: is_nil(r.start_date) or r.start_date <= ^date,
      select: %{
        id: fragment("'receipt-' || ?", r.id),
        date: type(p.inserted_at, :date),
        post_month: p.post_month,
        desc:
          fragment(
            "'Payment from tenant ' || ? || ' ' || ? || '(Unit ' || ? || ')'",
            t.first_name,
            t.last_name,
            u.number
          ),
        debit_account_id: fragment("?::bigint", ^cash),
        credit_account_id: cc.account_id,
        amount: r.amount,
        ref: p.tenant_id,
        source: "tenants"
      }
    )
  end

  def prepaid_payment_debits(
        property_id,
        %{"receivable" => receivable, "prepaid" => prepaid},
        "accrual",
        date
      ) do
    from(
      r in Receipt,
      join: p in assoc(r, :payment),
      join: t in assoc(p, :tenant),
      join: c in assoc(r, :charge),
      join: l in assoc(c, :lease),
      join: u in assoc(l, :unit),
      where: p.property_id == ^property_id and c.bill_date > p.inserted_at,
      where: is_nil(r.stop_date) or r.stop_date > ^date,
      where: is_nil(r.start_date) or r.start_date <= ^date,
      select: %{
        id: fragment("'receipt-' || ?", r.id),
        date: c.bill_date,
        post_month: p.post_month,
        desc:
          fragment(
            "'Prepaid Rent from tenant ' || ? || ' ' || ? || '(Unit ' || ? || ')'",
            t.first_name,
            t.last_name,
            u.number
          ),
        debit_account_id: type(^prepaid, :integer),
        credit_account_id: type(^receivable, :integer),
        amount: r.amount,
        ref: p.tenant_id,
        source: "tenants"
      }
    )
  end

  def prepaid_payment_debits(property_id, %{"prepaid" => prepaid}, "cash", date) do
    from(
      r in Receipt,
      join: p in assoc(r, :payment),
      join: t in assoc(p, :tenant),
      join: c in assoc(r, :charge),
      join: cc in assoc(c, :charge_code),
      join: l in assoc(c, :lease),
      join: u in assoc(l, :unit),
      where: p.property_id == ^property_id and c.bill_date > p.inserted_at,
      where: is_nil(r.stop_date) or r.stop_date > ^date,
      where: is_nil(r.start_date) or r.start_date <= ^date,
      select: %{
        id: fragment("'receipt-' || ?", r.id),
        date: c.bill_date,
        post_month: p.post_month,
        desc:
          fragment(
            "'Prepaid Rent from tenant ' || ? || ' ' || ? || '(Unit ' || ? || ')'",
            t.first_name,
            t.last_name,
            u.number
          ),
        debit_account_id: type(^prepaid, :integer),
        credit_account_id: cc.account_id,
        amount: r.amount,
        ref: p.tenant_id,
        source: "tenants"
      }
    )
  end

  def prepaid_tenant_payments(
        property_id,
        %{"prepaid" => prepaid, "cash" => cash},
        "accrual",
        date
      ) do
    from(
      p in Payment,
      left_join: r in assoc(p, :receipts),
      left_join: c in assoc(r, :charge),
      left_join: l in assoc(p, :lease),
      left_join: u in assoc(l, :unit),
      join: t in assoc(p, :tenant),
      where: p.property_id == ^property_id,
      where: is_nil(r.stop_date) or r.stop_date > ^date,
      where: is_nil(r.start_date) or r.start_date <= ^date,
      where: p.status != "voided",
      having: coalesce(sum(r.amount), 0) < p.amount or max(c.bill_date) > p.inserted_at,
      select: %{
        id: fragment("'payment-' || ?", p.id),
        date: type(p.inserted_at, :date),
        post_month: p.post_month,
        desc:
          fragment(
            "'Payment from tenant ' || ? || ' ' || ? || '(Unit ' || ? || ')'",
            t.first_name,
            t.last_name,
            u.number
          ),
        debit_account_id: type(^cash, :integer),
        credit_account_id: type(^prepaid, :integer),
        amount:
          p.amount -
            coalesce(
              sum(r.amount)
              |> filter(c.bill_date < p.inserted_at),
              0
            ),
        ref: p.tenant_id,
        source: "tenants"
      },
      group_by: [p.id, t.id, u.id]
    )
  end

  def prepaid_tenant_payments(property_id, %{"prepaid" => prepaid, "cash" => cash}, "cash", date) do
    from(
      p in Payment,
      left_join: r in assoc(p, :receipts),
      left_join: c in assoc(r, :charge),
      left_join: l in assoc(p, :lease),
      left_join: u in assoc(l, :unit),
      join: t in assoc(p, :tenant),
      where: p.property_id == ^property_id,
      where: is_nil(r.stop_date) or r.stop_date > ^date,
      where: is_nil(r.start_date) or r.start_date <= ^date,
      where: p.status != "voided",
      having: coalesce(sum(r.amount), 0) < p.amount or max(c.bill_date) < p.inserted_at,
      select: %{
        id: fragment("'payment-' || ?", p.id),
        date: type(p.inserted_at, :date),
        post_month: p.post_month,
        desc:
          fragment(
            "'Payment from tenant ' || ? || ' ' || ? || '(Unit ' || ? || ')'",
            t.first_name,
            t.last_name,
            u.number
          ),
        debit_account_id: type(^cash, :integer),
        credit_account_id: type(^prepaid, :integer),
        amount:
          p.amount -
            coalesce(
              sum(r.amount)
              |> filter(c.bill_date < p.inserted_at),
              0
            ),
        ref: p.tenant_id,
        source: "tenants"
      },
      group_by: [p.id, t.id, u.id]
    )
  end

  def non_tenant_payments(property_id, %{"cash" => cash}) do
    from(
      p in Payment,
      join: r in assoc(p, :receipts),
      join: a in assoc(r, :account),
      where: p.property_id == ^property_id,
      where: is_nil(p.application_id),
      select: %{
        id: fragment("'receipt-' || ?", r.id),
        date: type(p.inserted_at, :date),
        post_month: p.post_month,
        desc: fragment("? || ' from NP ' || ?", p.description, p.payer),
        debit_account_id: type(^cash, :integer),
        credit_account_id: a.id,
        amount: r.amount,
        ref: p.id,
        source: "payments"
      }
    )
  end

  def application_payments(property_id, %{"cash" => cash}) do
    from(
      p in Payment,
      join: r in assoc(p, :receipts),
      join: a in assoc(r, :account),
      join: app in assoc(p, :application),
      join: person in assoc(app, :persons),
      on: person.application_id == app.id and person.status == "Lease Holder",
      where: p.property_id == ^property_id,
      select: %{
        id: fragment("'receipt-' || ?", r.id),
        date: type(p.inserted_at, :date),
        post_month: p.post_month,
        desc: fragment("? || ' from ' || ?", p.description, max(person.full_name)),
        debit_account_id: type(^cash, :integer),
        credit_account_id: a.id,
        amount: r.amount,
        ref: app.id,
        source: "applications"
      },
      group_by: [p.id, r.id, a.id, app.id]
    )
  end

  def non_tenant_payment_refunds(property_id, %{"cash" => cash}) do
    from(
      p in Payment,
      join: r in assoc(p, :receipts),
      join: a in assoc(r, :account),
      where: p.property_id == ^property_id,
      where: not is_nil(p.refund_date),
      select: %{
        id: fragment("'refund-receipt-' || ?", r.id),
        date: p.refund_date,
        post_month: fragment("cast(date_trunc('month', ?) as date)", p.refund_date),
        desc: fragment("'Refund to NP ' || ?", p.payer),
        debit_account_id: a.id,
        credit_account_id: type(^cash, :integer),
        amount: r.amount,
        ref: p.id,
        source: "payments"
      }
    )
  end
end
