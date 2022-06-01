defmodule AppCount.Repo.Migrations.MoveMaterialsToContext do
  use Ecto.Migration

  def change do
    rename table(:maintenance__materials), to: table(:materials__materials)
    rename table(:maintenance__material_types), to: table(:materials__types)
    rename table(:maintenance__material_logs), to: table(:materials__logs)
    rename table(:maintenance__materials_orders), to: table(:materials__orders)
    rename table(:maintenance__materials_orders_items), to: table(:materials__order_items)
    rename table(:materials__order_items), :material_order_id, to: :order_id
    rename table(:maintenance__stocks), to: table(:materials__stocks)
  end
end
