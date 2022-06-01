defmodule AppCount.Repo.Migrations.CreatePermissions do
  use Ecto.Migration

  def change do
    create table(:admins__permissions) do
      add :admin_id, references(:admins__admins, on_delete: :delete_all), null: false
      add :entity_id, references(:admins__entities, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:admins__permissions, [:admin_id])
    create index(:admins__permissions, [:entity_id])
    create unique_index(:admins__permissions, [:admin_id, :entity_id])
  end
end
