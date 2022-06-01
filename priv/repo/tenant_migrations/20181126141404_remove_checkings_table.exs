defmodule AppCount.Repo.Migrations.RemoveCheckingsTable do
  use Ecto.Migration

  def change do
    drop table(:accounting__checkings)
  end
end
