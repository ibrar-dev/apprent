defmodule AppCount.Repo.Migrations.RemoveUniqueInvoicingConstraint do
  use Ecto.Migration

  def change do
    drop unique_index(:accounting__invoicings, [:property_id, :invoice_id, :account_id])
  end
end
