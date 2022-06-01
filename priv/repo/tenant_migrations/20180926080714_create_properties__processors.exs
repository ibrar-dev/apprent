defmodule AppCount.Repo.Migrations.CreatePropertiesProcessors do
  use Ecto.Migration

  def change do
    create table(:properties__processors) do
      add :name, :string, null: false
      add :type, :string, null: false
      add :keys, {:array, :text}, default: "{}", null: false
      add :property_id, references(:properties__properties, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:properties__processors, [:property_id, :type])
  end
end
