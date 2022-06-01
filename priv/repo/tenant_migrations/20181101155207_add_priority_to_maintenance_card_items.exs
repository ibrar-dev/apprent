defmodule AppCount.Repo.Migrations.AddPriorityToMaintenanceCardItems do
  use Ecto.Migration

  def change do
    alter table(:maintenance__cards) do
      add :priority, :integer
    end
  end
end
