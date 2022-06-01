defmodule AppCount.Repo.Migrations.CreateAccountingChecks do
  use Ecto.Migration

  def change do
    create table(:accounting__checks) do
      add :amount, :decimal, null: false
      add :number, :integer, null: false
      add :date, :date, null: false
      add :bank_account_id, references(:accounting__bank_accounts, on_delete: :delete_all), null: false
      add :property_id, references(:properties__properties, on_delete: :delete_all), null: false
      add :payee_id, references(:accounting__payees, on_delete: :delete_all), null: false
      add :invoice_id, references(:accounting__invoices, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:accounting__checks, [:bank_account_id])
    create index(:accounting__checks, [:property_id])
    create index(:accounting__checks, [:payee_id])
    create index(:accounting__checks, [:invoice_id])
    create unique_index(:accounting__checks, [:number, :bank_account_id])
  end
end
