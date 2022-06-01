defmodule AppCount.Repo.Migrations.CreateAccountingInvoicePayments do
  use Ecto.Migration

  def change do
    create table(:accounting__invoice_payments) do
      add :amount, :decimal
      add :invoicing_id, references(:accounting__invoicings, on_delete: :delete_all), null: false
      add :check_id, references(:accounting__checks, on_delete: :nilify_all)

      timestamps()
    end

    create unique_index(:accounting__invoice_payments, [:check_id, :invoicing_id])
  end
end
