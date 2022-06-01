defmodule AppCount.Repo.Migrations.UniqueIndexForCheckings do
  use Ecto.Migration

  def change do
    create unique_index(:accounting__checkings, [:check_id, :invoicing_id])
  end
end
