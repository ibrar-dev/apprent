defmodule AppCount.Ledgers.CustomerLedgerRepo do
  use AppCount.Core.GenericRepo, schema: AppCount.Ledgers.CustomerLedger

  @doc """
    ledger_balance is for internal ledgers only, not intended for external balances
  """
  def ledger_balance(%AppCount.Core.ClientSchema{name: client_schema, attrs: customer_ledger_id}) do
    ledger_balances_query()
    |> where([l], l.id == ^customer_ledger_id)
    |> select([_, payment, charge], coalesce(charge.sum, 0) - coalesce(payment.sum, 0))
    |> Repo.one(prefix: client_schema)
  end

  def ledger_balances_query(as_of_date \\ AppCount.current_date()) do
    from(
      ledger in @schema,
      left_join: payment in subquery(sum_payments(as_of_date)),
      on: payment.ledger_id == ledger.id,
      left_join: charge in subquery(sum_charges(as_of_date)),
      on: charge.ledger_id == ledger.id
    )
  end

  defp sum_charges(date) do
    from(
      charge in AppCount.Ledgers.Charge,
      select: %{
        ledger_id: charge.customer_ledger_id,
        sum: sum(charge.amount)
      },
      where: charge.bill_date <= ^date,
      group_by: [charge.customer_ledger_id]
    )
  end

  defp sum_payments(date) do
    end_of_day =
      date
      |> Timex.to_datetime()
      |> Timex.end_of_day()

    from(
      payment in AppCount.Ledgers.Payment,
      where: payment.status != "voided",
      select: %{
        ledger_id: payment.customer_ledger_id,
        sum: sum(payment.amount)
      },
      where: payment.inserted_at <= ^end_of_day,
      group_by: [payment.customer_ledger_id]
    )
  end
end
