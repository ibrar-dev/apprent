defmodule AppCount.Repo.Migrations.TrafficSourceRefForProspects do
  use Ecto.Migration

  def change do
    alter table(:prospects__prospects) do
      add :traffic_source_id, references(:prospects__traffic_sources, on_delete: :nothing)
      remove :traffic_source
    end

    create index(:prospects__prospects, [:traffic_source_id])
  end
end
