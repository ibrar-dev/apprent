defmodule AppCount.Repo.Migrations.CreatePropertiesFloorPlanFeatures do
  use Ecto.Migration

  def change do
    create table(:properties__floor_plan_features) do
      add :feature_id, references(:properties__features, on_delete: :delete_all), null: false
      add :floor_plan_id, references(:properties__floor_plans, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:properties__floor_plan_features, [:feature_id, :floor_plan_id])
  end
end
