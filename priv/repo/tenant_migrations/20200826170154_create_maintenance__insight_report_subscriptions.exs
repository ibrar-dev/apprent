defmodule AppCount.Repo.Migrations.CreateMaintenanceInsightReportSubscriptions do
  use Ecto.Migration

  def change do
    create table(:maintenance__insight_report_subscriptions) do
      add :type, :string, default: "daily", null: false
      add :property_id, references(:properties__properties, on_delete: :nothing)
      add :admin_id, references(:admins__admins, on_delete: :nothing)

      timestamps()
    end

    create index(:maintenance__insight_report_subscriptions, [:property_id])
    create index(:maintenance__insight_report_subscriptions, [:admin_id])
  end
end
