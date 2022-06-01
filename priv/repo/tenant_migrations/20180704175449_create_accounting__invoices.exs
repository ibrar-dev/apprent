defmodule AppCount.Repo.Migrations.CreateAccountingInvoices do
  use Ecto.Migration

  def change do
    create table(:accounting__invoices) do
      add :amount, :decimal, null: false
      add :post_month, :date, null: false
      add :document, :string
      add :account_id, references(:accounting__accounts, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:accounting__invoices, [:account_id])
  end
end
