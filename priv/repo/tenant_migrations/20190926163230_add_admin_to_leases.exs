defmodule AppCount.Repo.Migrations.AddAdminToLeases do
  use Ecto.Migration

  def change do
    alter table(:leases__leases) do
      add :admin, :string
      add :renewal_admin, :string
    end
  end
end
