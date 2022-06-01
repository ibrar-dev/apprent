defmodule AppCount.Repo.Migrations.AddBlueMoonLeaseIdToApplication do
  use Ecto.Migration

  def change do
    alter table(:rent_apply__rent_applications) do
      add :bluemoon_lease_id, :bigint
    end
  end
end
