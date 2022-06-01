defmodule AppCount.Repo.Migrations.FixUnitFeaturesForeignKeys do
  use Ecto.Migration

  def up do
    execute "ALTER TABLE #{prefix()}.properties__unit_features DROP CONSTRAINT properties__unit_features_unit_id_fkey"
    execute "ALTER TABLE #{prefix()}.properties__unit_features DROP CONSTRAINT properties__unit_features_feature_id_fkey"
    alter table(:properties__unit_features) do
      modify :unit_id, references(:properties__units, on_delete: :delete_all)
      modify :feature_id, references(:properties__features, on_delete: :delete_all)
    end
  end

  def down do
    execute "ALTER TABLE #{prefix()}.properties__unit_features DROP CONSTRAINT properties__unit_features_unit_id_fkey"
    execute "ALTER TABLE #{prefix()}.properties__unit_features DROP CONSTRAINT properties__unit_features_feature_id_fkey"
    alter table(:properties__unit_features) do
      modify :unit_id, references(:properties__units, on_delete: :nothing)
      modify :feature_id, references(:properties__features, on_delete: :nothing)
    end
  end
end
