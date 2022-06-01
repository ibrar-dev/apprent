defmodule AppCount.Accounting.Receipts do
  alias AppCount.Accounting.Receipts

  def receipts(lease_id) do
    lease_id
    |> Receipts.GetLedger.ledger_for()
    |> Receipts.ClearLedger.clear_ledger()
    |> Receipts.ProcessLedger.do_process()
    |> Receipts.Calculator.calculate_receipts()
    |> Receipts.Insert.do_insert()
  end
end
