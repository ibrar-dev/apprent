defmodule AppCount.Repo.Migrations.CreateActions do
  use Ecto.Migration

  def change do
    create table(:actions) do
      add :description, :string, null: false
      add :permission_type, :string, null: false
      add :module_id, references(:modules, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:actions, [:module_id])
  end
end
