defmodule AppCount.Repo.Migrations.CreateMaintenanceCards do
  use Ecto.Migration

  def change do
    create table(:maintenance__cards) do
      add :items, :jsonb, null: false, default: "{}"
      add :deadline, :date, null: false
      add :occupancy_id, references(:properties__occupancies, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:maintenance__cards, [:occupancy_id])
  end
end
