defmodule AppCount.Repo.Migrations.UniqueConstraintsForMaterials do
  use Ecto.Migration

  def change do
    create unique_index(:maintenance__materials, [:ref_number, :stock_id])
    create unique_index(:maintenance__materials, [:name, :stock_id])
  end
end
