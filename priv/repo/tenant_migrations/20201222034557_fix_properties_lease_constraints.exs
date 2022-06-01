defmodule AppCount.Repo.Migrations.FixPropertiesLeaseConstraints do
  use Ecto.Migration

  def up do
    drop_if_exists constraint(:properties__charges, :leases_charges_non_zero)
    drop_if_exists constraint(:properties__charges, :properties_charges_non_zero)
    create constraint(:properties__charges, :non_zero_amount, check: "amount != 0")
  end

  def down do
    create constraint(:properties__charges, :properties_charges_non_zero, check: "amount != 0")
    create constraint(:properties__charges, :leases_charges_non_zero, check: "amount != 0")
  end
end
