defmodule AppCount.Repo.Migrations.MoveRenewalTablesToLeasingContext do
  use Ecto.Migration

  def change do
    alter table(:leases__custom_packages) do
      remove :lease_id
      add :lease_id, references(:leasing__leases, on_delete: :delete_all)
    end

    drop table(:leases__external_balances)

    rename table(:leases__custom_packages), to: table(:leasing__custom_packages)
    rename table(:leases__renewal_packages), to: table(:leasing__renewal_packages)
    rename table(:leases__renewal_periods), to: table(:leasing__renewal_periods)
  end
end
