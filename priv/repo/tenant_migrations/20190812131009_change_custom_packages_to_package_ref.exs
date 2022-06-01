defmodule AppCount.Repo.Migrations.ChangeCustomPackagesToPackageRef do
  use Ecto.Migration

  def change do
    drop constraint(:leases__custom_packages, :custom_min_max_overlap)
    alter table(:leases__custom_packages) do
      add :renewal_package_id, references(:leases__renewal_packages, on_delete: :delete_all), null: false
      remove :renewal_period_id
      remove :min
      remove :max
      modify :notes, :jsonb, null: false, default: "[]"
    end
    drop index(:leases__custom_packages, [:lease_id])
    create unique_index(:leases__custom_packages, [:renewal_package_id, :lease_id])
  end
end
