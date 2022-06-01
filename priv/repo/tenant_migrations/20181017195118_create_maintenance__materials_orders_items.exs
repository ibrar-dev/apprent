defmodule AppCount.Repo.Migrations.CreateMaintenanceMaterialsOrdersItems do
  use Ecto.Migration

  def change do
    create table(:maintenance__materials_orders_items) do
      add :quantity, :integer, null: true
      add :status, :string, null: false
      add :cost, :decimal, null: false, default: 0
      add :material_id, references(:maintenance__materials, on_delete: :delete_all), null: false
      add :material_order_id, references(:maintenance__materials_orders, on_delete: :delete_all), null: true

      timestamps()
    end

  end
end
