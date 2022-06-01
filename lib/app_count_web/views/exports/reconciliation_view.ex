defmodule AppCountWeb.Exports.ReconciliationView do
  use AppCountWeb, :view

  def get_type(type) do
    reference = %{
      "check" => "Check",
      "journal_income" => "Journal Income",
      "journal_expence" => "Journal Expense",
      "nsf_payment" => "NSF",
      "batch" => "Batch",
      "payment_wo_batch" => "Payment"
    }

    reference[type]
  end

  def is_deposit(type) do
    Enum.member?(["batch", "payment_wo_batch", "journal_income"], type)
  end

  def is_payment(type) do
    Enum.member?(["journal_expence", "check", "nsf_payment"], type)
  end
end
