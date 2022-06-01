defmodule AppCount.Repo.Migrations.CreateSkills do
  use Ecto.Migration

  def change do
    create table(:maintenance__skills) do
      add :tech_id, references(:maintenance__techs, on_delete: :delete_all), null: false
      add :category_id, references(:maintenance__categories,  on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:maintenance__skills, [:tech_id, :category_id])
  end
end
