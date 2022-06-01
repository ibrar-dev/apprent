defmodule AppCount.Repo.Migrations.AddFieldsToMaintenanceCards do
  use Ecto.Migration

  def change do
    alter table(:maintenance__cards) do
      remove :items
      remove :lease_id
      add :move_out_date, :date, null: false
      modify :unit_id, :bigint, null: false
    end

    create index(:materials__toolbox_items, [:assignment_id])
    create unique_index(:maintenance__cards, [:unit_id])
  end
end
