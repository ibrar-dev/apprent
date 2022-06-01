defmodule AppCount.Repo.Migrations.AddsAccountsAccountsAllowSms do
  use Ecto.Migration

  def change do
    alter table(:accounts__accounts) do
      add :allow_sms, :boolean, default: false, null: false
    end
    
    alter table(:tenants__tenants) do
      remove :allow_sms, :boolean, default: false, null: false
    end

  end
end
