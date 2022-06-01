defmodule AppCount.Repo.Migrations.AddUniqueIndexToOrgChart do
  use Ecto.Migration


  def change do
    create unique_index(:admins__org_charts, [:admin_id])
  end
end
