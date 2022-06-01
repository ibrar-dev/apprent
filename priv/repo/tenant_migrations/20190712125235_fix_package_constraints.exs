defmodule AppCount.Repo.Migrations.FixPackageConstraints do
  use Ecto.Migration

  def up do
    drop constraint(:leases__renewal_packages, :min_max_overlap)
    create constraint(:leases__renewal_packages, :min_max_overlap, exclude: ~s|gist (renewal_period_id WITH =, int4range("min", "max") WITH &&)|)
  end

  def down do
    drop constraint(:leases__renewal_packages, :min_max_overlap)
    create constraint(:leases__renewal_packages, :min_max_overlap, exclude: ~s|gist (renewal_period_id WITH =, int4range("min", "max") WITH &&)|)
  end
end
