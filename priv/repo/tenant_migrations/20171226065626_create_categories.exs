defmodule AppCount.Repo.Migrations.CreateCategories do
  use Ecto.Migration

  def change do
    create table(:maintenance__categories) do
      add :name, :string, null: false
      add :path, {:array, :integer}, null: false, default: "{}"
      add :parent_id, references(:maintenance__categories, on_delete: :delete_all)

      timestamps()
    end

    create unique_index(:maintenance__categories, [:name, :parent_id])
  end
end
