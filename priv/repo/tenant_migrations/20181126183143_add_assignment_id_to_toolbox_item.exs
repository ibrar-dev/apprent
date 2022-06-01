defmodule AppCount.Repo.Migrations.AddAssignmentIdToToolboxItem do
  use Ecto.Migration

  def change do
    alter table(:materials__toolbox_items) do
      add :assignment_id, references(:maintenance__assignments, on_delete: :nothing), null: true
      add :returned_by, :string, null: true
    end

    alter table(:materials__materials) do
      add :image, :string, null: true
      add :location, :jsonb, null: true
    end

    alter table(:materials__stocks) do
      add :image, :string, null: true
    end
  end
end
