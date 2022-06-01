defmodule AppCount.Repo.Migrations.AddTypeToClosings do
  use Ecto.Migration

  def change do
    alter table(:accounting__closings) do
      add :type, :string, null: false
    end

    drop unique_index(:accounting__closings, [:month, :property_id])
    create unique_index(:accounting__closings, [:month, :property_id, :type])
  end
end
