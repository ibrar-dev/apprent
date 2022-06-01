defmodule AppCount.Repo.Migrations.AddWareHouseIDToStock do
  use Ecto.Migration

  def change do
    alter table(:materials__stocks) do
      add :warehouse_id, references(:materials__warehouses, on_delete: :nothing)
    end
  end
end
