defmodule AppCount.Repo.Migrations.FixLeasesConstraint do
  use Ecto.Migration

  def up do
    drop constraint(:properties__leases, :duration_overlap)
    clause = ~s/(CASE WHEN "move_out_date" IS NULL THEN "end_date" ELSE "move_out_date" END)/
    exclude = ~s/gist (unit_id WITH =, daterange("start_date", #{clause}) WITH &&)/
    create constraint(:properties__leases, :duration_overlap, exclude: exclude)
  end

  def down do
    drop constraint(:properties__leases, :duration_overlap)
    exclude = ~s|gist (unit_id WITH =, daterange("start_date", "end_date") WITH &&)|
    create constraint(:properties__leases, :duration_overlap, exclude: exclude)
  end
end
