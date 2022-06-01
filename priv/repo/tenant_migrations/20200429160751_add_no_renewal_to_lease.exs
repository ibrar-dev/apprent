defmodule AppCount.Repo.Migrations.AddNoRenewalToLease do
  use Ecto.Migration

  def change do
    alter table(:leases__leases) do
      add :no_renewal, :boolean, default: false
    end
  end
end
