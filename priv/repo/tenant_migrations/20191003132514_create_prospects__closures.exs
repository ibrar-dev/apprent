defmodule AppCount.Repo.Migrations.CreateProspectsClosures do
  use Ecto.Migration

  def change do
    create table(:prospects__closures) do
      add :date, :date, null: false
      add :start_time, :integer, null: false
      add :end_time, :integer, null: false
      add :reason, :string, null: false
      add :admin, :string, null: false
      add :property_id, references(:properties__properties, on_delete: :delete_all), null: false

      timestamps()
    end

    alter table(:prospects__showings) do
      add :cancellation, :date, null: true
    end

    create index(:prospects__closures, [:property_id])
    create constraint(:prospects__closures, :closures_end_after_start, check: "start_time < end_time")
    create constraint(:prospects__closures, :closure_date_not_in_past, check: "date >= now()")
  end
end
