defmodule Properties.Repo.Migrations.CreateUnits do
  use Ecto.Migration

  def change do
    create table(:properties__units) do
      add :number, :string, null: false
      add :property_id, references(:properties__properties, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:properties__units, [:property_id, :number])
  end
end
