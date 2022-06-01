defmodule AppCount.Repo.Migrations.RemovePersonsFromRentApplyLeases do
  use Ecto.Migration

  def change do
    alter table(:rent_apply__leases) do
      remove :persons
    end
  end
end
