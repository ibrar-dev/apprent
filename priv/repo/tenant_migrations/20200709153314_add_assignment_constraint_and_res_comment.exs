defmodule AppCount.Repo.Migrations.AddAssignmentConstraintAndResComment do
  use Ecto.Migration

  def change do
    alter table(:maintenance__assignments) do
      add :resident_comment, :string, null: true
    end
    create constraint(:maintenance__assignments, :must_have_assigner, check: "tech_id IS NOT NULL OR payee_id IS NOT NULL")
    create index(:maintenance__assignments, [:payee_id])
  end
end
