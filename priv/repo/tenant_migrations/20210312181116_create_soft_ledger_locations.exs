defmodule AppCount.Repo.Migrations.CreateSoftLedgerLocations do
  use Ecto.Migration

  def change do
    create table(:soft_ledger__locations) do
      add :property_id, :integer, null: false
      add :location_id, :string, null: false
      timestamps()
    end

    create index(:soft_ledger__locations, [:location_id])
    create index(:soft_ledger__locations, [:property_id])
  end
end
