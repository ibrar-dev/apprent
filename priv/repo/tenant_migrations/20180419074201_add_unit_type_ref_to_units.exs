defmodule AppCount.Repo.Migrations.AddUnitTypeRefToUnits do
  use Ecto.Migration

  def change do
    alter table(:properties__units) do
      add :unit_type_id, references(:properties__unit_types, on_delete: :nilify_all)
    end

    create index(:properties__units, [:unit_type_id])
  end
end
