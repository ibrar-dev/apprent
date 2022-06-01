defmodule AppCount.Repo.Migrations.AddStatusToMaintenanceOrder do
  use Ecto.Migration

  def change do
    alter table(:maintenance__orders) do
      add :status, :string, null: true
    end
  end
end
