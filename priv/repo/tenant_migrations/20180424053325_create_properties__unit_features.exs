defmodule AppCount.Repo.Migrations.CreatePropertiesUnitFeatures do
  use Ecto.Migration

  def change do
    create table(:properties__unit_features) do
      add :unit_id, references(:properties__units, on_delete: :nothing)
      add :feature_id, references(:properties__features, on_delete: :nothing)

      timestamps()
    end

    create unique_index(:properties__unit_features, [:unit_id, :feature_id])
  end
end
