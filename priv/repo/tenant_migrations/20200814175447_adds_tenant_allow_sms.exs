defmodule AppCount.Repo.Migrations.AddsTenantAllowSms do
  use Ecto.Migration

  def change do
    alter table(:tenants__tenants) do
      add :allow_sms, :boolean, default: false, null: false
    end
  end
end
