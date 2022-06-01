defmodule AppCount.Repo.Migrations.MoveAmountsToInvoicings do
  use Ecto.Migration

  def change do
    alter table(:accounting__invoicings) do
      add :amount, :decimal, null: false
      add :amount_paid, :decimal, null: false
      add :notes, :text
    end

    alter table(:accounting__invoices) do
      remove :amount
      remove :amount_paid
    end
  end
end
