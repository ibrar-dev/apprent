defmodule AppCount.Repo.Migrations.CreateProspectsSettings do
  use Ecto.Migration

  def change do
    create table(:prospects__openings) do
      add :wday, :integer, null: false
      add :showing_slots, :integer, null: false, default: 1
      add :start_time, :integer, null: false
      add :end_time, :integer, null: false
      add :property_id, references(:properties__properties, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:prospects__openings, [:property_id])
  end
end
