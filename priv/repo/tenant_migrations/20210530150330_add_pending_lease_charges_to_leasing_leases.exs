defmodule AppCount.Repo.Migrations.AddPendingLeaseChargesToLeasingLeases do
  use Ecto.Migration

  def change do
    alter table(:leasing__leases) do
      add :pending_default_lease_charges, {:array, :integer}, default: []
    end
  end
end
