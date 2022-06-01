defmodule AppCount.Repo.Migrations.GeocodeProperties do
  use Ecto.Migration

  def change do
    alter table(:properties__properties) do
      add :lat, :decimal
      add :lng, :decimal
    end
  end
end
