defmodule AppCount.Repo.Migrations.DropClosingsAndAllowTenantChecks do
  use Ecto.Migration

  def change do
    drop table(:leases__closings)
    alter table(:accounting__checks) do
      modify :payee_id, :bigint, null: true
      add :tenant_id, references(:properties__tenants, on_delete: :delete_all)
    end

    create constraint(:accounting__checks, :has_payee, check: "payee_id IS NOT NULL OR tenant_id IS NOT NULL")
    create constraint(:accounting__checks, :has_only_one_payee, check: "payee_id IS NULL OR tenant_id IS NULL")
    create index(:accounting__checks, [:tenant_id])
  end
end
