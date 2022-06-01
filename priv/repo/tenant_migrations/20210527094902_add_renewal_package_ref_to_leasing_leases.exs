defmodule AppCount.Repo.Migrations.AddRenewalPackageRefToLeasingLeases do
  use Ecto.Migration

  def change do
    alter table(:leasing__leases) do
      add :renewal_package_id, references(:leasing__renewal_packages, on_delete: :nilify_all)
    end

    alter table(:leasing__custom_packages) do
      modify :lease_id, :bigint, null: false
    end

    create index(:leasing__leases, [:renewal_package_id])
    create index(:leasing__custom_packages, [:lease_id])
    create index(:leasing__custom_packages, [:renewal_package_id])
  end
end
