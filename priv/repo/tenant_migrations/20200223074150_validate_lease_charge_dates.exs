defmodule AppCount.Repo.Migrations.ValidateLeaseChargeDates do
  use Ecto.Migration

  def change do
    create constraint(
             :properties__charges,
             :lease_charges_valid_dates,
             check: "from_date IS NULL OR to_date IS NULL OR from_date < to_date"
           )
  end
end
