defmodule AppCount.Repo.Migrations.UniqueIndexOnOccupancies do
  use Ecto.Migration

  def change do
    drop index(:properties__occupancies, [:unit_id])
    drop index(:properties__occupancies, [:tenant_id])
#    create unique_index(:properties__occupancies, [:unit_id, :tenant_id])
  end
end
