defmodule AppCount.Repo.Migrations.AddMaterialsToAssignments do
  use Ecto.Migration

  def change do
    alter table(:maintenance__assignments) do
      add :materials, :jsonb, default: "[]"
      add :tech_comments, :text
    end
  end
end
