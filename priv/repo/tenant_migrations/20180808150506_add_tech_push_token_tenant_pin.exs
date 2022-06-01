defmodule AppCount.Repo.Migrations.AddTechPushTokenTenantPin do
  use Ecto.Migration

  def change do
    alter table(:maintenance__techs) do
      add :push_token, :string, null: true
    end

    alter table(:properties__tenants) do
      add :package_pin, :string, null: true
    end

    alter table(:properties__packages) do
      remove :pin
    end
  end
end
