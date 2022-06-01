defmodule AppCount.Repo.Migrations.NonZeroChargesConstraint do
  use Ecto.Migration

  def change do
    create constraint(:properties__charges, :properties_charges_non_zero, check: "amount != 0")
    create constraint(:accounting__charges, :accounting_charges_non_zero, check: "amount != 0")
  end
end
