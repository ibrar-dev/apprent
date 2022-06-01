defmodule AppCount.Repo.Migrations.AddAlarmCodeToTenants do
  use Ecto.Migration

  def change do
    alter table(:properties__tenants) do
      add :alarm_code, :string
    end
  end
end
