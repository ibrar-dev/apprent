defmodule AppCount.Repo.Migrations.RemoveAmountPaidFromInvoicings do
  use Ecto.Migration

  def change do
    alter table(:accounting__invoicings) do
      remove :amount_paid
    end
  end
end
