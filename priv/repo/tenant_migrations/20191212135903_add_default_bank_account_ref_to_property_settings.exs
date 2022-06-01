defmodule AppCount.Repo.Migrations.AddDefaultBankAccountRefToPropertySettings do
  use Ecto.Migration

  def change do
    alter table(:properties__settings) do
      add :default_bank_account_id, references(:accounting__bank_accounts, on_delete: :nilify_all)
    end

    create index(:properties__settings, [:default_bank_account_id])
  end
end
