defmodule AppCount.Repo.Migrations.CreateModules do
  use Ecto.Migration

  def change do
    create table(:modules) do
      add :name, :string, null: false

      timestamps()
    end

    create unique_index(:modules, [:name])
  end
end
