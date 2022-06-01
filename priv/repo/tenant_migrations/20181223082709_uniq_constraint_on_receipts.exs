defmodule AppCount.Repo.Migrations.UniqConstraintOnReceipts do
  use Ecto.Migration

  def change do
    drop index(:accounting__receipts, [:concession_id])
    create unique_index(:accounting__receipts, [:charge_id, :concession_id])
  end
end
