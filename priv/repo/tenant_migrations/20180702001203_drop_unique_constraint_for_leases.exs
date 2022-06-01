defmodule AppCount.Repo.Migrations.DropUniqueConstraintForLeases do
  use Ecto.Migration

  def change do
    execute "DROP INDEX IF EXISTS #{prefix()}.properties_occupancies_unit_id_tenant_id_index"
  end
end
