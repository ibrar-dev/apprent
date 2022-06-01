defmodule AppCount.Repo.Migrations.AddFieldsToMaterials do
  use Ecto.Migration

  def change do
    alter table(:maintenance__materials) do
      add :type_id, references(:maintenance__material_types, on_delete: :delete_all), null: false
      add :ref_number, :string, null: false
    end
  end
end
