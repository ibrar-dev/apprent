defmodule AppCount.Repo.Migrations.AddUniqueIndexToClosings do
  use Ecto.Migration

  def change do
    create unique_index(:accounting__closings, [:month, :property_id])
  end
end
