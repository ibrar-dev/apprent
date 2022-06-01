defmodule AppCount.Repo.Migrations.RequiredUUIDForTenants do
  use Ecto.Migration

  def change do
    alter table(:properties__tenants) do
      modify :uuid, :uuid, null: false
    end
  end
end
