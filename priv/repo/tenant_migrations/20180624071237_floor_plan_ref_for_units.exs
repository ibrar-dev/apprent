defmodule AppCount.Repo.Migrations.FloorPlanRefForUnits do
  use Ecto.Migration

  def change do
    alter table(:properties__units) do
      add :floor_plan_id, references(:properties__floor_plans, on_delete: :nilify_all)
    end
  end
end
