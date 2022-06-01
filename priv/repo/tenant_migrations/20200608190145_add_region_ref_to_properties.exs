defmodule AppCount.Repo.Migrations.AddRegionRefToProperties do
  use Ecto.Migration

  def change do
    alter table(:properties__properties) do
      add :region_id, references(:properties__regions, on_delete: :nilify_all)
    end
    create index(:properties__properties, [:region_id])
  end
end
