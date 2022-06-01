defmodule AppCount.Repo.Migrations.AddActiveToPets do
  use Ecto.Migration

  def change do
    alter table(:tenants__pets) do
      add :active, :boolean, default: true, null: false
    end
    alter table(:tenants__vehicles) do
      add :active, :boolean, default: true, null: false
    end
  end
end
