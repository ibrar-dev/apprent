defmodule AppCount.Repo.Migrations.CreateAdminsOrgCharts do
  use Ecto.Migration

  def change do
    create table(:admins__org_charts) do
      add :admin_id, references(:admins__admins)
      add :status, :string, defualt: "available"
      add :path, {:array, :integer}, null: false, default: "{}"
      timestamps()
    end

  end
end
