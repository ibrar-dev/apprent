defmodule AppCount.Repo.Migrations.AddMoveInToMaintenanceCards do
  use Ecto.Migration

  def change do
    alter table(:maintenance__cards) do
      add :move_in_date, :date
    end
  end
end
