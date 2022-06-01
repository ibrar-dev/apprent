defmodule AppCount.Repo.Migrations.CreateMaintenanceMaterialsOrders do
  use Ecto.Migration

  def change do
    create table(:maintenance__materials_orders) do
      add :number, :string, null: false
      add :status, :string, null: false
      add :tax, :decimal, null: false, default: 0
      add :shipping, :decimal, null: false, default: 0
      add :history, :jsonb, null: false

      timestamps()
    end

  end
end
