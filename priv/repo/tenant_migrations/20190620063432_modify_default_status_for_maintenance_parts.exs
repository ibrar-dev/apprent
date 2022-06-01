defmodule AppCount.Repo.Migrations.ModifyDefaultStatusForMaintenanceParts do
  use Ecto.Migration

  def change do
    alter table(:maintenance__parts) do
      modify :status, :string, default: "pending", null: false
      modify :name, :string, null: false
    end
  end
end
