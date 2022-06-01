defmodule AppCount.Repo.Migrations.MoveRentApplyLeasesToLeasesContext do
  use Ecto.Migration

  def change do
    execute "alter table #{prefix()}.rent_apply__leases rename constraint rent_apply__leases_pkey to leases__forms_pkey"
    execute "alter table #{prefix()}.rent_apply__leases rename constraint rent_apply__leases_application_id_fkey to leases__forms_application_id_fkey"
    execute "alter index #{prefix()}.rent_apply__leases_application_id_index rename to leases__forms_application_id_index"
    execute "ALTER SEQUENCE #{prefix()}.rent_apply__leases_id_seq RENAME TO leases__forms_id_seq;"

    rename table(:rent_apply__leases), to: table(:leases__forms)

  end
end
