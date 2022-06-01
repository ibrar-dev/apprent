defmodule AppCount.Repo.Migrations.CreateAccountingSoftLedgerLocations do
  use Ecto.Migration

  def change do
    create table(:accounting__soft_ledger_locations) do
      add :name, :string, nil: false
      add :location_id, :integer, nil: false

      timestamps()
    end

  end
end
