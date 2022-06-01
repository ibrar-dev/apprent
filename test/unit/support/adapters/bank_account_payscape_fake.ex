defmodule AppCount.Support.Adapters.BankAccountPayscapeFake do
  @moduledoc """
  Provides fake data during testing

  Status 00 seems to indicate a successful ACH payment. Anything else indicates a failure.
  Status codes: https://www.propay.com/en-US/Documents/API-Docs/ProPay-API-Manual-Appendix
  """

  def process_payment(_amount, _source, _processor) do
    {:ok, %{transaction_id: "Payscap-transaction_id", status: "00", invoice_number: "1234567"}}
  end
end
