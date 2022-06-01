defmodule AppCount.Repo.Migrations.CreateSoftLedgerAccounts do
  use Ecto.Migration

  def change do
    create table(:soft_ledger__accounts) do
      add :soft_ledger_underscore_id, :integer, null: false
      add :app_count_account_id, :integer, null: false
      timestamps()
    end

    create index(:soft_ledger__accounts, [:app_count_account_id])
   end
end
