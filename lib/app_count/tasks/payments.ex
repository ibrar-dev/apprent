# deprecated
defmodule AppCount.Tasks.Payments do
  import Ecto.Query
  import AppCount.EctoExtensions
  alias AppCount.Repo
  alias AppCount.Accounting
  alias AppCount.Tenants
  alias AppCount.Tenants.Tenant
  alias AppCount.Accounting.Receipt
  alias AppCount.Ledgers.Payment
  use AppCount.Decimal

  def payments_to_leases(tenant_id) do
    leases =
      from(
        t in Tenant,
        join: l in assoc(t, :leases),
        where: t.id == ^tenant_id,
        select: l,
        order_by: [
          asc: l.start_date
        ]
      )
      |> Repo.all()

    from(
      p in Payment,
      join: t in assoc(p, :tenant),
      where: is_nil(p.lease_id),
      where: p.tenant_id == ^tenant_id,
      order_by: [
        asc: p.inserted_at
      ]
    )
    |> Repo.all()
    |> match_payment_to_leases(leases)
  end

  def perform(""), do: nil
  def perform(nil), do: nil

  def perform(tenant_id) do
    tenant_ids =
      from(
        t in Tenant,
        join: l in assoc(t, :leases),
        join: ten in assoc(l, :tenants),
        where: t.id == ^tenant_id,
        select: array(ten.id)
      )
      |> Repo.one()

    if tenant_ids do
      Enum.each(tenant_ids, &payments_to_leases/1)

      Tenants.ledger_query(tenant_id: tenant_id)
      |> join(:left, [c], ch in Ledgers.Charge, on: c.id == ch.id and c.type == "charge")
      |> where([c, ch], (is_nil(ch.reversal_id) and ch.status != "reversal") or is_nil(ch.id))
      |> where([c], c.notes != "voided" or c.type != "payment")
      |> Repo.all()
      |> Enum.group_by(& &1.unit_id)
      |> Map.values()
      |> Enum.reduce([], &process_ledger(&1, &2))
      |> cleanup(tenant_ids)
    end
  end

  defp cleanup(ids, tenant_ids) do
    from(
      r in Receipt,
      join: p in assoc(r, :payment),
      where: r.id not in ^ids and p.tenant_id in ^tenant_ids
    )
    |> Repo.delete_all()

    from(
      r in Receipt,
      join: c in assoc(r, :concession),
      join: l in assoc(c, :lease),
      join: t in assoc(l, :tenants),
      where: r.id not in ^ids and t.id in ^tenant_ids
    )
    |> Repo.delete_all()
  end

  defp process_ledger(items, receipt_ids) do
    grouped = Enum.group_by(items, & &1.type)
    create_receipts(grouped["charge"] || [], grouped["payment"] || [], receipt_ids)
  end

  defp create_receipts(bills, payments, receipt_ids) when is_list(bills) and is_list(payments) do
    {bills, payments}
    |> sort_bills()
    |> process_lists()
    |> insert_receipts
    |> Enum.concat(receipt_ids)
  end

  defp create_receipts(_, _, _), do: nil

  defp process_lists({bills, payments}) do
    {_unmatched, inserts} = Enum.reduce(bills, {payments, []}, &process_payment/2)
    inserts
  end

  # bill is resolved, move on to next one
  defp process_payment(%{amount: a}, {payments, inserts}) when a == 0, do: {payments, inserts}

  # no payments found
  defp process_payment(_, {nil, inserts}), do: {[], inserts}

  # ran out of payments now just run through unresolved bills
  defp process_payment(_, {[], inserts}), do: {[], inserts}

  # payment fully resolved, move on to next one
  defp process_payment(bill, {[%{amount: a} | rest], ins}) when a <= 0,
    do: process_payment(bill, {rest, ins})

  # match the payment to the bill
  defp process_payment(bill, {[first | rest], ins}) do
    res = match_payment(bill, first)

    cond do
      # payment fully resolved, move on to next one
      res.payment.amount <= 0 -> process_payment(res.bill, {rest, [res.insert | ins]})
      # bill fully resolved, move on to next one
      res.bill.amount <= 0 -> {[res.payment | rest], [res.insert | ins]}
    end
  end

  defp match_payment(%{amount: bill, id: bill_id}, %{amount: payment, id: id} = p) do
    receipt_amount = Enum.min([payment, bill])

    now =
      AppCount.current_time()
      |> DateTime.to_naive()
      |> NaiveDateTime.truncate(:second)

    field = if p.type == "concession", do: :concession_id, else: :payment_id

    attrs =
      %{
        amount: receipt_amount,
        charge_id: bill_id,
        updated_at: now,
        inserted_at: now
      }
      |> Map.put(field, id)

    %{
      insert: attrs,
      payment: %{
        amount: payment - receipt_amount,
        id: id,
        type: p.type
      },
      bill: %{
        amount: bill - receipt_amount,
        id: bill_id
      }
    }
  end

  defp insert_receipts(inserts) do
    {payments, concessions} =
      inserts
      |> Enum.reduce(
        {[], []},
        fn
          %{payment_id: _} = ins, {p, c} -> {[ins | p], c}
          %{concession_id: _} = ins, {p, c} -> {p, [ins | c]}
        end
      )

    {_, p_ids} =
      Repo.insert_all(
        Receipt,
        payments,
        on_conflict: {:replace_all_except, [:id]},
        conflict_target: [:charge_id, :payment_id, :start_date, :stop_date],
        returning: [:id]
      )

    {_, c_ids} =
      Repo.insert_all(
        Receipt,
        concessions,
        on_conflict: {:replace_all_except, [:id]},
        conflict_target: [:charge_id, :concession_id, :start_date, :stop_date],
        returning: [:id]
      )

    Enum.map(p_ids ++ c_ids, & &1.id)
  end

  defp sort_bills({bills, payments}) do
    rent_account = Accounting.SpecialAccounts.get_account(:rent).name
    hap_rent_account = Accounting.SpecialAccounts.get_account(:hap_rent).name

    {neg, pos} =
      (bills ++ (payments || []))
      |> Enum.reduce(
        {[], []},
        fn
          %{type: "payment"} = element, {bills, payments} ->
            {bills, [element | payments]}

          %{date: ts, amount: a} = c, {bills, payments} when a < 0 ->
            con = %{
              amount: a * -1,
              id: c.id,
              type: "concession",
              date: ts
            }

            {bills, [con | payments]}

          element, {bills, payments} ->
            {[element | bills], payments}
        end
      )

    sorted_bills =
      Enum.sort_by(
        neg,
        fn bill ->
          date_ts = Timex.to_unix(bill.date)

          cond do
            bill.amount < 0 -> date_ts - 1
            bill.account == rent_account -> date_ts
            bill.account == hap_rent_account -> date_ts
            true -> date_ts + 1
          end
        end
      )

    sorted_payments = Enum.sort_by(pos, fn %{date: date} -> Timex.to_unix(date) end)

    {sorted_bills, sorted_payments}
  end

  defp match_payment_to_leases([], _), do: nil
  defp match_payment_to_leases(_, []), do: nil

  defp match_payment_to_leases([payment | payments], [lease | leases]) do
    if leases == [] || Timex.before?(payment.inserted_at, hd(leases).start_date) do
      payment
      |> Payment.changeset(%{lease_id: lease.id})
      |> Repo.update()

      match_payment_to_leases(payments, [lease] ++ leases)
    else
      match_payment_to_leases([payment] ++ payments, leases)
    end
  end
end
