defmodule AppCount.Repo.Migrations.CreatePropertiesFeatures do
  use Ecto.Migration

  def change do
    create table(:properties__features) do
      add :name, :string, null: false
      add :price, :decimal, null: false
      add :property_id, references(:properties__properties, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:properties__features, [:property_id, :name])
  end
end
