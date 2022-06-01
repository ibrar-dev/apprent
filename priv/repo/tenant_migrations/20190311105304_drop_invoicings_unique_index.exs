defmodule AppCount.Repo.Migrations.DropInvoicingsUniqueIndex do
  use Ecto.Migration

  def change do
    drop_if_exists unique_index(:accounting__invoicings, [:property_id, :invoice_id])
  end
end
