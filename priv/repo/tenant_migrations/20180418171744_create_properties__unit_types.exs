defmodule AppCount.Repo.Migrations.CreatePropertiesUnitTypes do
  use Ecto.Migration

  def change do
    create table(:properties__unit_types) do
      add :name, :string, null: false
      add :rent, :decimal, null: false
      add :bedrooms, :integer, null: false
      add :bathrooms, :integer, null: false
      add :area, :decimal, null: false
      add :description, :text
      add :deposit, :decimal
      add :property_id, references(:properties__properties, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:properties__unit_types, [:property_id, :name])
  end
end
