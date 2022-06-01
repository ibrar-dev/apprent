defmodule AppCount.Repo.Migrations.FixCustomPackageConstraint do
  use Ecto.Migration

  def up do
    drop constraint(:leases__custom_packages, :custom_min_max_overlap)
    create constraint(:leases__custom_packages, :custom_min_max_overlap, exclude: ~s|gist (lease_id WITH =, int4range("min", "max") WITH &&)|)
  end

  def down do
    drop constraint(:leases__custom_packages, :custom_min_max_overlap)
    create constraint(:leases__custom_packages, :custom_min_max_overlap, exclude: ~s|gist (lease_id WITH =, int4range("min", "max") WITH &&)|)
  end
end
