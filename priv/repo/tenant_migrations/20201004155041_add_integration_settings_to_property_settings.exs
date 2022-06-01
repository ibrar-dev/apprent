defmodule AppCount.Repo.Migrations.AddIntegrationSettingsToPropertySettings do
  use Ecto.Migration

  def change do
    alter table(:properties__settings) do
      add :integration, :string
      add :sync_payments, :boolean, null: false, default: false
      add :sync_ledgers, :boolean, null: false, default: false
      add :sync_residents, :boolean, null: false, default: false
    end
  end
end
