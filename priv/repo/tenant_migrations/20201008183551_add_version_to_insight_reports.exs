defmodule AppCount.Repo.Migrations.AddVersionToInsightReports do
  use Ecto.Migration

  def change do
    alter table(:maintenance__insight_reports) do
      add :version, :integer, null: false, default: 1
    end
  end
end
