defmodule AppCount.Support.Adapters.BankAccountPayscapeFake do
  @moduledoc """
  Provides fake data during testing

  Status 00 seems to indicate a successful ACH payment. Anything else indicates a failure.
  Status codes: https://www.propay.com/en-US/Documents/API-Docs/ProPay-API-Manual-Appendix
  """

  def process_payment(_amount, _source, _processor) do
    txn_id = Enum.random(10000..100000000)
    invoice_num = Enum.random(1000..10000)
    {:ok, %{transaction_id: "#{txn_id}", status: "00", invoice_number: "#{invoice_num}"}}
  end
end
