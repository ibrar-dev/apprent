defmodule AppCount.Repo.Migrations.CreatePropertiesResidentEventAttendance do
  use Ecto.Migration

  def change do
    create table(:properties__resident_event_attendances) do
      add :resident_event_id, references(:properties__resident_events, on_delete: :delete_all), null: false
      add :tenant_id, references(:properties__tenants, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:properties__resident_event_attendances, [:resident_event_id])
    create index(:properties__resident_event_attendances, [:tenant_id])
  end
end
