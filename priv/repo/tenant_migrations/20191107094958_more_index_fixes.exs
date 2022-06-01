defmodule AppCount.Repo.Migrations.MoreIndexFixes do
  use Ecto.Migration

  def change do
    execute "alter index IF EXISTS #{prefix()}.accounts__purchases_tenant_id_index rename to rewards__purchases_tenant_id_index"
    execute "alter index IF EXISTS #{prefix()}.accounts__rewards_account_id_index rename to rewards__awards_tenant_id_index"
    execute "alter index IF EXISTS #{prefix()}.accounts__rewards_type_id_index rename to rewards__awards_type_id_index"
  end
end
