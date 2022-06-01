defmodule AppCount.Repo.Migrations.UniqueIndexForEntityNames do
  use Ecto.Migration

  def change do
    create unique_index(:admins__entities, [:name])
  end
end
