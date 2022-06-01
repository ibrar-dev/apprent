defmodule AppCount.Repo.Migrations.UniqueCategories do
  use Ecto.Migration

  def change do
    drop index(:maintenance__categories, [:name, :parent_id])
    create unique_index(:maintenance__categories, [:name, :path])
  end
end
