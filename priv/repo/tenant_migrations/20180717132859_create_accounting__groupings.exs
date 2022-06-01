defmodule AppCount.Repo.Migrations.CreateAccountingGroupings do
  use Ecto.Migration

  def change do
    create table(:accounting__groupings) do
      add :property_id, references(:properties__properties, on_delete: :delete_all), null: false
      add :entity_id, references(:accounting__entities, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:accounting__groupings, [:property_id, :entity_id])
  end
end
