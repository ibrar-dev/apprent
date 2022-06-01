defmodule AppCount.Repo.Migrations.DefaultUUIDForTenants do
  use Ecto.Migration

  def change do
    alter table(:tenants__tenants) do
      modify :uuid, :uuid, default: fragment("uuid_generate_v4()"), null: false
    end
  end
end
