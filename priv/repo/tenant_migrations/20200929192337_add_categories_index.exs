defmodule AppCount.Repo.Migrations.AddCategoriesIndex do
  use Ecto.Migration

  def change do
    create index("maintenance__categories", [:parent_id])
    create index("maintenance__categories", [:name])
  end
end
