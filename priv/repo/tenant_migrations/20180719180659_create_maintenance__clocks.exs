defmodule AppCount.Repo.Migrations.CreateMaintenanceClocks do
  use Ecto.Migration

  def change do
    create table(:maintenance__clocks) do
      add :in, :boolean, default: false, null: false
      add :time, :naive_datetime, null: false
      add :location, :map, null: true
      add :tech_id, references(:maintenance__techs, on_delete: :delete_all), null: false

      timestamps()
    end

  end
end
