defmodule AppCount.Repo.Migrations.DropSoftLedgerLocations do
  use Ecto.Migration

  def change do
    drop table(:soft_ledger__locations) 
  end
end
