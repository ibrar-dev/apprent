defmodule AppCount.Repo.Migrations.CreateAccountingClasses do
  use Ecto.Migration

  def change do
    create table(:accounting__classes) do
      add :name, :string, null: false

      timestamps()
    end

    create unique_index(:accounting__classes, [:name])

  end
end
