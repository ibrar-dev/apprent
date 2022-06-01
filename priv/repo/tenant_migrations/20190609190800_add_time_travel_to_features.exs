defmodule AppCount.Repo.Migrations.AddTimeTravelToFeatures do
  use Ecto.Migration

  def change do
    alter table(:properties__features) do
      add :start_date, :date
      add :stop_date, :date
    end

    drop_if_exists unique_index(:properties__features, [:property_id, :name])
    drop_if_exists unique_index(:properties_features, [:property_id, :name])
    create unique_index(:properties__features, [:property_id, :name], where: "stop_date IS NULL")
  end
end
