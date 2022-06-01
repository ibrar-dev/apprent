defmodule AppCount.Repo.Migrations.MoveTenantsToTenantsContext do
  use Ecto.Migration

  def change do
    execute "alter table #{prefix()}.properties__tenants rename constraint properties__tenants_pkey to tenants__tenants_pkey"
    execute "alter table #{prefix()}.properties__tenants rename constraint properties__tenants_application_id_fkey to tenants__tenants_application_id_fkey"
    execute "alter index IF EXISTS #{prefix()}.properties_tenants_application_id_index rename to tenants__tenants_application_id_index"
    execute "alter index IF EXISTS #{prefix()}.properties__tenants_application_id_index rename to tenants__tenants_application_id_index"
    execute "alter index IF EXISTS #{prefix()}.properties_tenants_first_name_last_name_email_index rename to tenants__tenants_first_name_last_name_email_index"
    execute "alter index IF EXISTS #{prefix()}.properties__tenants_first_name_last_name_email_index rename to tenants__tenants_first_name_last_name_email_index"
    execute "alter index IF EXISTS #{prefix()}.properties_tenants_uuid_index rename to tenants__tenants_uuid_index"
    execute "alter index IF EXISTS #{prefix()}.properties__tenants_uuid_index rename to tenants__tenants_uuid_index"
    execute "ALTER SEQUENCE #{prefix()}.properties__tenants_id_seq RENAME TO tenants__tenants_id_seq;"

    rename table(:properties__tenants), to: table(:tenants__tenants)
  end
end
