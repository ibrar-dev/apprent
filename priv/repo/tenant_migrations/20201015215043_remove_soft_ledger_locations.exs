defmodule AppCount.Repo.Migrations.RemoveSoftLedgerLocations do
  use Ecto.Migration

  def change do
    drop table("accounting__soft_ledger_locations")
  end
end
