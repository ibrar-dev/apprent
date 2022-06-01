defmodule AppCount.Repo.Migrations.MoveLeasesToLeasesContext do
  use Ecto.Migration

  def change do
    execute "alter table #{prefix()}.properties__leases rename constraint properties__leases_pkey to leases__leases_pkey"
    execute "alter table #{prefix()}.properties__leases rename constraint properties__leases_document_id_fkey to leases__leases_document_id_fkey"
    execute "alter table #{prefix()}.properties__leases rename constraint properties__leases_move_out_reason_id_fkey to leases__leases_move_out_reason_id_fkey"
    execute "alter table #{prefix()}.properties__leases rename constraint properties__leases_renewal_id_fkey to leases__leases_renewal_id_fkey"
    execute "alter table #{prefix()}.properties__leases rename constraint properties__leases_renewal_package_id_fkey to leases__leases_renewal_package_id_fkey"
    execute "alter table #{prefix()}.properties__leases rename constraint properties__leases_unit_id_fkey to leases__leases_unit_id_fkey"

    execute "alter index #{prefix()}.properties__leases_document_id_index rename to leases__leases_document_id_index"
    execute "alter index #{prefix()}.properties__leases_move_out_reason_id_index rename to leases__leases_move_out_reason_id_index"
    execute "alter index #{prefix()}.properties__leases_renewal_id_index rename to leases__leases_renewal_id_index"
    execute "ALTER SEQUENCE #{prefix()}.properties__leases_id_seq RENAME TO leases__leases_id_seq;"

    alter table(:properties__leases) do
      remove :tenant_id
    end

    rename table(:properties__leases), to: table(:leases__leases)
  end
end
