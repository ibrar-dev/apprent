defmodule AppCount.Repo.Migrations.AddPerUnitToMaterials do
  use Ecto.Migration

  def change do
    alter table(:materials__materials) do
      add :per_unit, :integer, default: 1, null: false
    end
  end
end
