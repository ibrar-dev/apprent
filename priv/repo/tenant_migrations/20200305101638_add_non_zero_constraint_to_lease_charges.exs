defmodule AppCount.Repo.Migrations.AddNonZeroConstraintToLeaseCharges do
  use Ecto.Migration

  def change do
    create constraint(:properties__charges, :leases_charges_non_zero, check: "amount != 0")
  end
end
