defmodule AppCount.Repo.Migrations.AddIndiciesToOccupancies do
  use Ecto.Migration

  def change do
    create unique_index(:properties__occupancies, [:tenant_id, :unit_id])
  end
end
