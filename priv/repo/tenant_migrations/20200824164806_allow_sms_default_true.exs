defmodule AppCount.Repo.Migrations.AllowSmsDefaultTrue do
  use Ecto.Migration

  def up do
    alter table(:accounts__accounts) do
      modify(:allow_sms, :boolean, default: true)
    end

    alter table(:maintenance__orders) do
      modify(:allow_sms, :boolean, default: true)
    end
  end

  def down do
    alter table(:accounts__accounts) do
      modify(:allow_sms, :boolean, default: false)
    end

    alter table(:maintenance__orders) do
      modify(:allow_sms, :boolean, default: false)
    end
  end
end
