defmodule AppCount.Repo.Migrations.AddUniqueConstraintForInvoicings do
  use Ecto.Migration

  def change do
    create unique_index(:accounting__invoicings, [:property_id, :invoice_id, :account_id])
  end
end
