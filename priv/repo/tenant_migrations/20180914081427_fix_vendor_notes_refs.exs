defmodule AppCount.Repo.Migrations.FixVendorNotesRefs do
  use Ecto.Migration

  def up do
    execute "ALTER TABLE #{prefix()}.vendors__notes DROP CONSTRAINT vendors__notes_tenant_id_fkey"
    execute "ALTER TABLE #{prefix()}.vendors__notes DROP CONSTRAINT vendors__notes_admin_id_fkey"
    execute "ALTER TABLE #{prefix()}.vendors__notes DROP CONSTRAINT vendors__notes_tech_id_fkey"
    execute "ALTER TABLE #{prefix()}.vendors__notes DROP CONSTRAINT vendors__notes_vendor_id_fkey"
    alter table(:vendors__notes) do
      modify :tenant_id, references(:properties__tenants, on_delete: :delete_all)
      modify :admin_id, references(:admins__admins, on_delete: :delete_all)
      modify :tech_id, references(:maintenance__techs, on_delete: :delete_all)
      modify :vendor_id, references(:vendors__vendors, on_delete: :delete_all)
    end
  end

  def down do
    execute "ALTER TABLE #{prefix()}.vendors__notes DROP CONSTRAINT vendors__notes_tenant_id_fkey"
    execute "ALTER TABLE #{prefix()}.vendors__notes DROP CONSTRAINT vendors__notes_admin_id_fkey"
    execute "ALTER TABLE #{prefix()}.vendors__notes DROP CONSTRAINT vendors__notes_tech_id_fkey"
    execute "ALTER TABLE #{prefix()}.vendors__notes DROP CONSTRAINT vendors__notes_vendor_id_fkey"
    alter table(:vendors__notes) do
      modify :tenant_id, references(:properties__tenants, on_delete: :nothing)
      modify :admin_id, references(:admins__admins, on_delete: :nothing)
      modify :tech_id, references(:maintenance__techs, on_delete: :nothing)
      modify :vendor_id, references(:vendors__vendors, on_delete: :nothing)
    end
  end
end
