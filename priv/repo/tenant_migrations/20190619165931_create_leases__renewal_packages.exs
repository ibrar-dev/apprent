defmodule AppCount.Repo.Migrations.CreateLeasesRenewalPackages do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS btree_gist"
    create table(:leases__renewal_packages) do
      add :min, :integer, null: false
      add :max, :integer, null: false
      add :base, :string, null: false, default: "Market"
      add :amount, :decimal, null: false
      add :dollar, :boolean, null: false, default: true
      add :resident_selected, :boolean, null: true
      add :period_id, references(:leases__renewal_periods, on_delete: :delete_all)

      timestamps()
    end
    create constraint(:leases__renewal_packages, :min_max_overlap, exclude: ~s|gist (int4range("min", "max") WITH &&)|)
#    create constraint(:leases__renewal_packages, :min_less_than_max, check: "MIN <= MAX")
    create index(:leases__renewal_packages, [:period_id])
  end
end
