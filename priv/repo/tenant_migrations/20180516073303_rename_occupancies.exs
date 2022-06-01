defmodule AppCount.Repo.Migrations.RenameOccupancies do
  use Ecto.Migration

  def change do
    rename table(:properties__occupancies), to: table(:properties__leases)
    rename table(:properties__charges), :occupancy_id, to: :lease_id
    rename table(:maintenance__cards), :occupancy_id, to: :lease_id
    drop index(:properties__occupancies, [:tenant_id, :unit_id])
    create unique_index(:properties__leases, [:tenant_id, :unit_id])
    drop index(:properties__charges, [:occupancy_id])
    create index(:properties__charges, [:lease_id])
    drop unique_index(:maintenance__cards, [:occupancy_id])
    create unique_index(:maintenance__cards, [:lease_id])
  end
end
