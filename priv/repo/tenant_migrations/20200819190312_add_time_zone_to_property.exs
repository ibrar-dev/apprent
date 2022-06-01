defmodule AppCount.Repo.Migrations.AddTimeZoneToProperty do
  use Ecto.Migration

  def change do
    alter table("properties__properties") do
      add :time_zone, :string, default: "US/Eastern"
    end
  end
end
