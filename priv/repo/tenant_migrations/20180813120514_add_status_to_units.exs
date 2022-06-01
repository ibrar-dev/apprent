defmodule AppCount.Repo.Migrations.AddStatusToUnits do
  use Ecto.Migration

  def change do
    alter table(:properties__units) do
      add :status, :string
    end

    create index(:properties__units, [:floor_plan_id])
    create index(:properties__tenants, [:application_id])
    create index(:properties__properties, [:stock_id])
    create index(:properties__packages, [:unit_id])
    create index(:properties__leases, [:tenant_id])
    create index(:rent_apply__rent_applications, [:property_id])
  end
end
