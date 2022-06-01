defmodule AppCount.Repo.Migrations.CreateVendorPropertiesJoinTable do
  use Ecto.Migration

  def change do
    create table(:vendor__properties) do
      add :vendor_id, references(:vendors__vendors, on_delete: :delete_all), null: false
      add :property_id, references(:properties__properties,  on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:vendor__properties, [:vendor_id, :property_id])
  end
end
