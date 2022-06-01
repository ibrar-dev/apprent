defmodule AppCount.Repo.Migrations.AddOrdersAllowSms do
  use Ecto.Migration

  def change do
    alter table(:maintenance__orders) do
      add :allow_sms, :boolean, default: false, null: false
    end
  end
end
