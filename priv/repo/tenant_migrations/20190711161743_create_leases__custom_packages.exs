defmodule AppCount.Repo.Migrations.CreateLeasesCustomPackages do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS btree_gist"
    create table(:leases__custom_packages) do
      add :amount, :decimal, null: false
      add :min, :integer, null: false
      add :max, :integer, null: false
      add :renewal_period_id, references(:leases__renewal_periods, on_delete: :delete_all), null: false
      add :lease_id, references(:leases__leases, on_delete: :delete_all), null: false

      timestamps()
    end

    create constraint(:leases__custom_packages, :custom_min_max_overlap, exclude: ~s|gist (int4range("min", "max") WITH &&)|)
    create index(:leases__custom_packages, [:renewal_period_id])
    create index(:leases__custom_packages, [:lease_id])
  end
end
