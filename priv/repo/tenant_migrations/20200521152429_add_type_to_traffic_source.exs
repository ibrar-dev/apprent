defmodule AppCount.Repo.Migrations.AddTypeToTrafficSource do
  use Ecto.Migration

  def change do
    alter table(:prospects__traffic_sources) do
      add :type, :string, null: true
    end
  end
end
