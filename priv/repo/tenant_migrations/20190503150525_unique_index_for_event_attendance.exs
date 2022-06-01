defmodule AppCount.Repo.Migrations.UniqueIndexForEventAttendance do
  use Ecto.Migration

  def change do
    create unique_index(:properties__resident_event_attendances, [:resident_event_id, :tenant_id])
  end
end
