defmodule AppCount.Repo.Migrations.AddTenantIdToPackages do
  use Ecto.Migration

  def change do
    alter table(:properties__packages) do
      add :tenant_id, :bigint
    end
  end
end
