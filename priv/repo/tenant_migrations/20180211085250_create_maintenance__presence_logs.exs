defmodule AppCount.Repo.Migrations.CreateMaintenancePresenceLogs do
  use Ecto.Migration

  def change do
    create table(:maintenance__presence_logs) do
      add :present, :boolean, default: false, null: false
      add :tech_id, references(:maintenance__techs, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:maintenance__presence_logs, [:tech_id])
  end
end
