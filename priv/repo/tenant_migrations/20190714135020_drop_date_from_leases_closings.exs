defmodule AppCount.Repo.Migrations.DropDateFromLeasesClosings do
  use Ecto.Migration

  def change do
    alter table(:leases__closings) do
      remove :date
    end
  end
end
