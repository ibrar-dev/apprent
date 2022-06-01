defmodule AppCount.Repo.Migrations.AddHistoryToAssignments do
  use Ecto.Migration

  def change do
    alter table(:maintenance__assignments) do
      add :history, :jsonb, default: "[]"
    end
  end
end
