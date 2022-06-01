defmodule AppCount.Repo.Migrations.MakeInvoicePaymentAmountRequired do
  use Ecto.Migration

  def change do
    alter table(:accounting__invoice_payments) do
      modify :amount, :decimal, null: false
    end
  end
end
