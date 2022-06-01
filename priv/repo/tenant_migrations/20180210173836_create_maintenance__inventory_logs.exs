defmodule AppCount.Repo.Migrations.CreateMaintenanceInventoryLogs do
  use Ecto.Migration

  def change do
    create table(:maintenance__inventory_logs) do
      add :old, :integer, null: false
      add :new, :integer, null: false
      add :source, :string, null: false
      add :material_id, references(:maintenance__materials, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:maintenance__inventory_logs, [:material_id])
  end
end
