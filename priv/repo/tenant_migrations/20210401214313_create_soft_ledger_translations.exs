defmodule AppCount.Repo.Migrations.CreateSoftLedgerTranslations do
  use Ecto.Migration

 def change do
    create table(:soft_ledger__translations) do
      add :soft_ledger_type, :string, null: false
      add :soft_ledger_underscore_id, :integer, null: false
      add :app_count_struct, :string, null: false
      add :app_count_id, :integer, null: false
      timestamps()
    end

    create index(:soft_ledger__translations, [:app_count_struct, :app_count_id])
   end

  end
