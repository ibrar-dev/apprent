defmodule AppCount.Repo.Migrations.CreatePropertiesEvents do
  use Ecto.Migration

  def change do
    create table(:properties__resident_events) do
      add :location, :string
      add :name, :string, null: false
      add :info, :text
      add :date, :date, null: false
      add :start_time, :integer, null: false
      add :end_time, :integer
      add :admin, :string, null: false
      add :property_id, references(:properties__properties, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:properties__resident_events, [:property_id])
  end
end
