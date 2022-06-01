defmodule AppCount.Repo.Migrations.ChangeLeasePersonsForeignKeyConstraints do
  use Ecto.Migration

  def change do
    drop_if_exists constraint(:properties__persons, "properties__persons_lease_id_fkey")
    alter table(:properties__persons) do
      modify :lease_id, references(:properties__leases, on_delete: :delete_all)
    end
  end
end
