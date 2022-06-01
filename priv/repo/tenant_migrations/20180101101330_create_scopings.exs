defmodule AppCount.Repo.Migrations.CreateScopings do
  use Ecto.Migration

  def change do
    create table(:properties__scopings) do
      add :entity_id, references(:admins__entities, on_delete: :delete_all), null: false
      add :property_id, references(:properties__properties, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:properties__scopings, [:property_id, :entity_id])
  end
end
