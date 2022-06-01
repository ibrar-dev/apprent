defmodule AppCount.Repo.Migrations.CreatePropertiesOccupancies do
  use Ecto.Migration

  def change do
    execute "alter table #{prefix()}.properties__leases rename constraint properties__occupancies_pkey to properties__leases_pkey"
    execute "alter table #{prefix()}.properties__leases rename constraint properties__occupancies_unit_id_fkey to properties__leases_unit_id_fkey"
    execute "ALTER SEQUENCE #{prefix()}.properties__occupancies_id_seq RENAME TO properties__leases_id_seq;"
    alter table(:properties__leases) do
      remove :type
      remove :notes
      remove :document
      remove :termination
      modify :tenant_id, :bigint, null: true
    end

    create index(:properties__leases, [:renewal_id])
    create index(:properties__leases, [:move_out_reason_id])

    create table(:properties__occupancies) do
      add :tenant_id, references(:properties__tenants, on_delete: :delete_all), null: false
      add :lease_id, references(:properties__leases, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:properties__occupancies, [:tenant_id, :lease_id])
  end
end
