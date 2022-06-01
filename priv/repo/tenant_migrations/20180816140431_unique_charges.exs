defmodule AppCount.Repo.Migrations.UniqueCharges do
  use Ecto.Migration

  def change do
    create unique_index(:properties__charges, [:lease_id, :account_id])
    create unique_index(:accounting__charges, [:lease_id, :bill_ts, :account_id])
  end
end
