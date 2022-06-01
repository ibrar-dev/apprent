defmodule AppCount.Repo.Migrations.CreateMaterialsInventory do
  use Ecto.Migration

  def change do
    create table(:materials__inventory) do
      add :inventory, :integer, null: false, default: 0
      add :stock_id, references(:materials__stocks, on_delete: :delete_all), null: false
      add :material_id, references(:materials__materials, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:materials__inventory, [:stock_id])
    create index(:materials__inventory, [:material_id])
  end
end
