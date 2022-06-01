defmodule AppCount.Accounting.Ledger.Charges do
  import Ecto.Query
  alias AppCount.Ledgers.Charge
  alias AppCount.Accounting.Receipt

  def lease_charges(property_id, %{"receivable" => account_id}) do
    from(
      c in Charge,
      join: l in assoc(c, :lease),
      join: ch in assoc(c, :charge_code),
      join: t in assoc(l, :tenants),
      join: u in assoc(l, :unit),
      where: u.property_id == ^property_id,
      where: c.amount > 0,
      select: %{
        id: fragment("'charge-' || ?", c.id),
        date: c.bill_date,
        post_month: c.post_month,
        desc:
          fragment(
            "'Lease charge for ' || (array_agg(? || ' ' || ? ORDER BY ? DESC))[1] || ' unit ' || ?",
            t.first_name,
            t.last_name,
            t.id,
            u.number
          ),
        debit_account_id: type(^account_id, :integer),
        credit_account_id: ch.account_id,
        amount: c.amount,
        ref: fragment("(array_agg(? ORDER BY ? DESC))[1]", t.id, t.id),
        source: "tenants"
      },
      group_by: [c.id, ch.account_id, u.id]
    )
  end

  def lease_concessions(property_id, %{"receivable" => account_id}, "accrual", _date) do
    from(
      c in Charge,
      join: ch in assoc(c, :charge_code),
      join: l in assoc(c, :lease),
      join: t in assoc(l, :tenants),
      join: u in assoc(l, :unit),
      where: u.property_id == ^property_id,
      where: c.amount < 0,
      select: %{
        id: fragment("'charge-' || ?", c.id),
        date: c.bill_date,
        post_month: c.post_month,
        desc:
          fragment(
            "'Lease charge for ' || (array_agg(? || ' ' || ? ORDER BY ? DESC))[1] || ' unit ' || ?",
            t.first_name,
            t.last_name,
            t.id,
            u.number
          ),
        debit_account_id: ch.account_id,
        credit_account_id: type(^account_id, :integer),
        amount: c.amount * -1,
        ref: fragment("(array_agg(? ORDER BY ? DESC))[1]", t.id, t.id),
        source: "tenants"
      },
      group_by: [c.id, ch.account_id, u.id]
    )
  end

  def lease_concessions(property_id, %{"cash" => account_id}, "cash", date) do
    from(
      r in Receipt,
      join: con in assoc(r, :concession),
      join: ch in assoc(r, :charge),
      join: cch in assoc(ch, :charge_code),
      join: l in assoc(ch, :lease),
      join: t in assoc(l, :tenants),
      join: u in assoc(l, :unit),
      where: u.property_id == ^property_id,
      where: is_nil(r.stop_date) or r.stop_date > ^date,
      where: is_nil(r.start_date) or r.start_date <= ^date,
      select: %{
        id: fragment("'charge-' || ?", ch.id),
        date: ch.bill_date,
        post_month: ch.post_month,
        desc:
          fragment(
            "'Lease charge for ' || (array_agg(? || ' ' || ? ORDER BY ? DESC))[1] || ' unit ' || ?",
            t.first_name,
            t.last_name,
            t.id,
            u.number
          ),
        debit_account_id: type(^account_id, :integer),
        credit_account_id: cch.account_id,
        amount: r.amount,
        ref: fragment("(array_agg(? ORDER BY ? DESC))[1]", t.id, t.id),
        source: "tenants"
      },
      group_by: [ch.id, cch.account_id, u.id, r.id]
    )
  end
end
