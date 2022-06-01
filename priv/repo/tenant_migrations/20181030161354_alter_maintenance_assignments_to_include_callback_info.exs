defmodule AppCount.Repo.Migrations.AlterMaintenanceAssignmentsToIncludeCallbackInfo do
  use Ecto.Migration

  def change do
    alter table(:maintenance__assignments) do
      add :callback_info, :jsonb
    end
  end
end
