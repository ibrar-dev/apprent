defmodule AppCount.Repo.Migrations.CreateMaintenanceMaterialLogs do
  use Ecto.Migration

  def change do
    create table(:maintenance__material_logs) do
      add :quantity, :integer
      add :admin, :string
      add :property_id, references(:properties__properties, on_delete: :delete_all)
      add :stock_id, references(:maintenance__stocks, on_delete: :delete_all)
      add :material_id, references(:maintenance__materials, on_delete: :delete_all)

      timestamps()
    end

  end
end
