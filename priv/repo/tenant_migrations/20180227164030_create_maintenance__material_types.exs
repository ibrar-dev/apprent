defmodule AppCount.Repo.Migrations.CreateMaintenanceMaterialTypes do
  use Ecto.Migration

  def change do
    create table(:maintenance__material_types) do
      add :name, :string, null: false

      timestamps()
    end

    create unique_index(:maintenance__material_types, [:name])
  end
end
