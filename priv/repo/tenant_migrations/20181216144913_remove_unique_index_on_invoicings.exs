defmodule AppCount.Repo.Migrations.RemoveUniqueIndexOnInvoicings do
  use Ecto.Migration

  def change do
    create index(:accounting__invoicings, [:invoice_id])
    create index(:accounting__invoicings, [:property_id])
  end
end
