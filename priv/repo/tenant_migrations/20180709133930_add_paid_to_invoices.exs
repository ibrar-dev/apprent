defmodule AppCount.Repo.Migrations.AddPaidToInvoices do
  use Ecto.Migration

  def change do
    alter table(:accounting__invoices) do
      add :amount_paid, :decimal, default: 0, null: false
    end
  end
end
