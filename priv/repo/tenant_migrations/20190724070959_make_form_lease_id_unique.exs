defmodule AppCount.Repo.Migrations.MakeFormLeaseIdUnique do
  use Ecto.Migration

  def change do
    drop index(:leases__forms, [:lease_id])
    create unique_index(:leases__forms, [:lease_id])
  end
end
