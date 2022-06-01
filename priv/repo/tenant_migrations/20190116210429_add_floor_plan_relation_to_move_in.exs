defmodule AppCount.Repo.Migrations.AddFloorPlanRelationToMoveIn do
  use Ecto.Migration

  def change do
    alter table(:rent_apply__move_ins) do
      add :floor_plan_id, references(:properties__floor_plans, on_delete: :nothing), null: true
    end

    create index(:rent_apply__move_ins, [:floor_plan_id])
  end
end
