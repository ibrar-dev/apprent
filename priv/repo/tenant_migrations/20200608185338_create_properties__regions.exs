defmodule AppCount.Repo.Migrations.CreatePropertiesRegions do
  use Ecto.Migration

  def change do
    create table(:properties__regions) do
      add :name, :string, null: false
      add :regional_supervisor_id, references(:admins__admins, on_delete: :nilify_all)

      timestamps()
    end
    create index(:properties__regions, [:regional_supervisor_id])
  end
end
