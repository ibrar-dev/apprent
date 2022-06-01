defmodule AppCount.Repo.Migrations.UniqueConstraintsForBills do
  use Ecto.Migration

  def change do
    create unique_index(:accounting__charges, [:bill_ts, :lease_id, :description])
  end
end
