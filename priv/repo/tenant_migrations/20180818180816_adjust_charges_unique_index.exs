defmodule AppCount.Repo.Migrations.AdjustChargesUniqueIndex do
  use Ecto.Migration

  def change do
    drop unique_index(:accounting__charges, [:lease_id, :bill_ts, :account_id])
    create unique_index(:accounting__charges, [:lease_id, :bill_ts, :account_id, :status])
  end
end
