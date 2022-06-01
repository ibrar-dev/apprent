defmodule AppCount.Repo.Migrations.CreateJobs do
  use Ecto.Migration

  def change do
    create table(:maintenance__jobs) do
      add :property_id, references(:properties__properties, on_delete: :delete_all), null: false
      add :tech_id, references(:maintenance__techs, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:maintenance__jobs, [:property_id, :tech_id])
  end
end
