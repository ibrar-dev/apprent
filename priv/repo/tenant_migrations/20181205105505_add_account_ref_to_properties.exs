defmodule AppCount.Repo.Migrations.AddAccountRefToProperties do
  use Ecto.Migration

  def change do
    alter table(:accounting__bank_accounts) do
      remove :account_id
      add :cash_account_id, references(:accounting__cash_accounts, on_delete: :delete_all), null: false
    end

    alter table(:accounting__invoices) do
      remove :account_id
      add :cash_account_id, references(:accounting__cash_accounts, on_delete: :delete_all), null: false
    end

    create index(:accounting__bank_accounts, [:cash_account_id])
    create index(:accounting__invoices, [:cash_account_id])
  end
end
