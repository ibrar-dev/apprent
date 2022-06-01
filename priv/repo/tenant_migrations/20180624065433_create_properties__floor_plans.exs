defmodule AppCount.Repo.Migrations.CreatePropertiesFloorPlans do
  use Ecto.Migration

  def change do
    create table(:properties__floor_plans) do
      add :name, :string, null: false
      add :property_id, references(:properties__properties, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:properties__floor_plans, [:property_id, :name])
  end
end
