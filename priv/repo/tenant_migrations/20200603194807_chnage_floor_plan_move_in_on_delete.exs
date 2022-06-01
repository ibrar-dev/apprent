defmodule AppCount.Repo.Migrations.ChnageFloorPlanMoveInOnDelete do
  use Ecto.Migration

  def up do
    execute "ALTER TABLE #{prefix()}.rent_apply__move_ins DROP CONSTRAINT rent_apply__move_ins_floor_plan_id_fkey"
    alter table(:rent_apply__move_ins) do
      modify :floor_plan_id, references(:properties__floor_plans, on_delete: :nilify_all), null: true
    end
  end

  def down do
    execute "ALTER TABLE #{prefix()}.rent_apply__move_ins DROP CONSTRAINT rent_apply__move_ins_floor_plan_id_fkey"
    alter table(:rent_apply__move_ins) do
      modify :floor_plan_id, references(:properties__floor_plans, on_delete: :nothing), null: true
    end
  end
end
