defmodule AppCount.Repo.Migrations.CreateCoreCaches do
  use Ecto.Migration

  def change do
    create table(:data__caches) do
      add :key, :string, null: false
      add :content, :text, null: false

      timestamps()
    end

    create unique_index(:data__caches, [:key])
  end
end
