defmodule AppCount.Repo.Migrations.AddAdminToLeasesForms do
  use Ecto.Migration

  def change do
    alter table(:leases__forms) do
      add :admin, :string, default: "Property Admin"
    end
  end
end
