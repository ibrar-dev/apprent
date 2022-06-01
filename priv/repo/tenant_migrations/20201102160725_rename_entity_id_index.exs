defmodule AppCount.Repo.Migrations.RenameEntityIdIndex do
  use Ecto.Migration

  def up do
    execute "alter index IF EXISTS admins__permissions_admin_id_entity_id_index rename to admins__permissions_admin_id_region_id_index"
    execute "alter index IF EXISTS admins__entities_name_index rename to admins__regions_name_index"
    execute "alter sequence IF EXISTS admins__entities_id_seq rename to admins__regions_id_seq"
  end

  def down do
    execute "alter index IF EXISTS  admins__permissions_admin_id_region_id_index rename to admins__permissions_admin_id_entity_id_index"
    execute "alter index IF EXISTS admins__regions_name_index rename to admins__entities_name_index "
    execute "alter sequence IF EXISTS admins__regions_id_seq rename to admins__entities_id_seq"
  end

end
