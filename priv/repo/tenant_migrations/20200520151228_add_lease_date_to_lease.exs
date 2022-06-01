defmodule AppCount.Repo.Migrations.AddLeaseDateToLease do
  use Ecto.Migration

  def change do
    alter table(:leases__leases) do
      add :lease_date, :date, null: true
    end

    alter table(:prospects__prospects) do
      remove :unit_type
      add :floor_plan_id, references(:properties__floor_plans, on_delete: :nothing), null: true
    end
  end
end
