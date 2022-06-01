defmodule AppCount.Repo.Migrations.AddConstraintsToOccupanices do
  use Ecto.Migration

  def up do
    execute "CREATE EXTENSION IF NOT EXISTS btree_gist"
    create constraint(:properties__occupancies, :valid_duration, check: "start_date < end_date")
    exclude = ~s|gist (unit_id WITH =, daterange("start_date", "end_date") WITH &&)|
    create constraint(:properties__occupancies, :duration_overlap, exclude: exclude)
  end

  def down do
    drop constraint(:properties__occupancies, :valid_duration)
    drop constraint(:properties__occupancies, :duration_overlap)
    execute "DROP EXTENSION IF EXISTS btree_gist"
  end
end
