defmodule AppCount.Repo.Migrations.DropUniqueIndexOnLeases do
  use Ecto.Migration

  def change do
    drop index(:properties__leases, [:tenant_id, :unit_id])
  end
end
