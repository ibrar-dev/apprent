defmodule AppCount.Repo.Migrations.AddBankAccountRefToDeposits do
  use Ecto.Migration

  def change do
    alter table(:accounting__batches) do
      add :bank_account_id, references(:accounting__bank_accounts, on_delete: :nothing)
    end

    create index(:accounting__batches, [:bank_account_id])
  end
end
