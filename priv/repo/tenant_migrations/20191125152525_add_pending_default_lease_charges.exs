defmodule AppCount.Repo.Migrations.AddPendingDefaultLeaseCharges do
  use Ecto.Migration

  def change do
    alter table(:leases__leases) do
      add :pending_default_lease_charges, {:array, :integer}, default: []
    end
  end
end
