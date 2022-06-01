defmodule AppCount.Repo.Migrations.CreateEntities do
  use Ecto.Migration

  def change do
    create table(:admins__entities) do
      add :name, :string, null: false
      add :resources, {:array, :string}, default: "{}", null: false

      timestamps()
    end

  end
end
