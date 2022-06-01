defmodule AppCount.Repo.Migrations.AccountRefForReciepts do
  use Ecto.Migration

  def change do
    alter table(:accounting__receipts) do
      add :account_id, references(:accounting__accounts, on_delete: :nothing)
      modify :charge_id, :bigint, null: true
    end

    create constraint(:accounting__receipts, :must_have_account, check: "charge_id IS NOT NULL OR account_id IS NOT NULL")
    create index(:accounting__receipts, [:account_id])
  end
end
