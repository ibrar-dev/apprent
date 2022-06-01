defmodule AppCount.Repo.Migrations.AddPropertyIdToPurchases do
  use Ecto.Migration

  def change do
    alter table(:rewards__purchases) do
      add :property_id, references(:properties__properties, on_delete: :delete_all), null: false
    end

    create index(:rewards__purchases, [:property_id])
  end
end
