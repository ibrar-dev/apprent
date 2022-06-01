defmodule AppCount.Repo.Migrations.AddAccountRefToInvoicePayments do
  use Ecto.Migration

  def change do
    alter table(:accounting__invoice_payments) do
      add :account_id, references(:accounting__accounts, on_delete: :nothing)
    end

    create index(:accounting__invoice_payments, [:account_id])
  end
end
