defmodule AppCount.Repo.Migrations.AddPackageIdToLease do
  use Ecto.Migration

  def change do
    alter table(:properties__leases) do
      add :renewal_package_id, references(:leases__renewal_packages, on_delete: :delete_all)
    end
    alter table(:leases__renewal_packages) do
      remove :period_id
      add :renewal_period_id, references(:leases__renewal_periods, on_delete: :delete_all)
    end
  end
end
