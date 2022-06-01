defmodule AppCount.Repo.Migrations.CreateProspectsShowings do
  use Ecto.Migration

  def change do
    create table(:prospects__showings) do
      add :date, :naive_datetime, null: false
      add :prospect_id, references(:prospects__prospects, on_delete: :delete_all), null: false
      add :property_id, references(:properties__properties, on_delete: :delete_all), null: false
      add :unit_id, references(:properties__units, on_delete: :delete_all)

      timestamps()
    end

    create index(:prospects__showings, [:prospect_id])
    create index(:prospects__showings, [:property_id])
    create index(:prospects__showings, [:unit_id])
    create unique_index(:prospects__showings, [:prospect_id, :date])
  end
end
