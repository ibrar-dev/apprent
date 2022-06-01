defmodule AppCount.Repo.Migrations.AlterMaintenanceCardsDeadline do
  use Ecto.Migration

  def change do
    alter table(:maintenance__cards) do
      modify :deadline, :date, null: true
    end
  end
end
