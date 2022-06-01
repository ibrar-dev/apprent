defmodule AppCount.Repo.Migrations.AdjustChargesIndexAgain do
  use Ecto.Migration

  def change do
    drop_if_exists unique_index(:accounting_charges, [:lease_id, :bill_ts, :account_id, :status])
    drop_if_exists unique_index(:accounting__charges, [:lease_id, :bill_ts, :account_id, :status])
    create unique_index(:accounting__charges, [:lease_id, :bill_date, :account_id, :status])
  end
end
