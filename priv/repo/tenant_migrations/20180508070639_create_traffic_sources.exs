defmodule AppCount.Repo.Migrations.CreateTrafficSources do
  use Ecto.Migration

  def change do
    create table(:prospects__traffic_sources) do
      add :name, :string, null: false

      timestamps()
    end

  end
end
