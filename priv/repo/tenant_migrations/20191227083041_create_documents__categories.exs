defmodule AppCount.Repo.Migrations.CreateDocumentsCategories do
  use Ecto.Migration

  def change do
    create table(:exports__categories) do
      add :name, :string, null: false
      add :admin_id, references(:admins__admins, on_delete: :delete_all)

      timestamps()
    end

    create index(:exports__categories, [:admin_id])
  end
end
