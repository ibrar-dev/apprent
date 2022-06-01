defmodule AppCount.Repo.Migrations.CreateAccountingInvoicings do
  use Ecto.Migration

  def change do
    create table(:accounting__invoicings) do
      add :invoice_id, references(:accounting__invoices, on_delete: :delete_all), null: false
      add :property_id, references(:properties__properties, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:accounting__invoicings, [:invoice_id, :property_id])
  end
end
