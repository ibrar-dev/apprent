defmodule AppCount.Accounting.Receipts.ProcessLedger do
  import Ecto.Query
  alias AppCount.Accounting
  alias AppCount.Repo

  defmodule Charge do
    defstruct [:id, :amount, :date, :until]
  end

  defmodule Concession do
    defstruct [:id, :amount, :date, :until]
  end

  defmodule Payment do
    defstruct [:id, :amount, :date, :until]
  end

  def do_process(lease_ids) do
    charge_query(lease_ids)
    |> union(^payment_query(lease_ids))
    |> subquery
    |> order_by([p], asc: p.date, asc: p.qualifier)
    |> Repo.all()
    |> Enum.map(&structify/1)
  end

  def structify(%{type: "payment"} = p), do: struct(Payment, p)

  def structify(%{type: "charge", amount: a} = c) when a < 0,
    do: struct(Concession, Map.put(c, :amount, abs(a)))

  def structify(%{type: "charge"} = c), do: struct(Charge, c)

  def charge_query(lease_ids) do
    cc_ids = [
      Accounting.SpecialAccounts.get_charge_code(:rent).id,
      Accounting.SpecialAccounts.get_charge_code(:hap_rent).id
    ]

    from(
      c in AppCount.Ledgers.Charge,
      left_join: r in assoc(c, :reversal),
      where: c.lease_id in ^lease_ids,
      where: c.status != "reversal",
      select: %{
        type: "charge",
        id: c.id,
        date: c.bill_date,
        amount: type(c.amount, :float),
        until: r.bill_date,
        qualifier: fragment("CASE WHEN ? = ANY (?) THEN 0 ELSE 1 END", c.charge_code_id, ^cc_ids)
      }
    )
  end

  def payment_query(lease_ids) do
    from(
      p in AppCount.Ledgers.Payment,
      left_join: nsf in assoc(p, :nsf),
      where: p.lease_id in ^lease_ids,
      where: p.status != "voided",
      select: %{
        type: "payment",
        id: p.id,
        date: type(p.inserted_at, :date),
        amount: type(p.amount, :float),
        until: type(nsf.bill_date, :date),
        qualifier: 1
      }
    )
  end
end
