defmodule AppCount.Repo.Migrations.AddBluemoonLeaseIdToLeases do
  use Ecto.Migration

  def change do
    alter table(:properties__leases) do
      add :bluemoon_lease_id, :string, null: true
    end

    alter table(:properties__settings) do
      add :bluemoon_credentials_confirmed, :date, null: true
    end
  end
end
