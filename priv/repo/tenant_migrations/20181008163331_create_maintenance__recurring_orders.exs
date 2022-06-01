defmodule AppCount.Repo.Migrations.CreateMaintenanceRecurringOrders do
  use Ecto.Migration

  def change do
    create table(:maintenance__recurring_orders) do
      add :schedule, :jsonb, null: false
      add :params, :jsonb, null: false
      add :name, :string, null: false
      add :property_id, references(:properties__properties, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:maintenance__recurring_orders, [:property_id])
  end
end
