defmodule AppCount.Repo.Migrations.CreateMaintenanceInsightReports do
  use Ecto.Migration

  def change do
    create table(:maintenance__insight_reports) do
      add :type, :string
      add :data, :map
      add :start_time, :utc_datetime
      add :end_time, :utc_datetime
      add :property_id, references(:properties__properties, on_delete: :nothing)

      timestamps()
    end

    create index(:maintenance__insight_reports, [:property_id])
  end
end
