defmodule AppCount.Repo.Migrations.AddJobsIndex do
  use Ecto.Migration

  def change do
    create index("maintenance__jobs", [:tech_id])
    create index("maintenance__jobs", [:property_id])
  end
end
