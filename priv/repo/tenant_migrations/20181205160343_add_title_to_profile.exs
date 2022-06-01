defmodule AppCount.Repo.Migrations.AddTitleToProfile do
  use Ecto.Migration

  def change do
    alter table(:admins__profiles) do
      add :title, :string, null: true
    end
  end
end
