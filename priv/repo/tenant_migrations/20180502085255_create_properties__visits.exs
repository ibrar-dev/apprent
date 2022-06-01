defmodule AppCount.Repo.Migrations.CreatePropertiesVisits do
  use Ecto.Migration

  def change do
    create table(:properties__visits) do
      add :description, :text, null: false
      add :admin, :string, null: false
      add :tenant_id, references(:properties__tenants, on_delete: :delete_all), null: false
      add :property_id, references(:properties__properties, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:properties__visits, [:tenant_id])
    create index(:properties__visits, [:property_id])
  end
end
