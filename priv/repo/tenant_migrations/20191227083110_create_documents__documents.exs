defmodule AppCount.Repo.Migrations.CreateDocumentsDocuments do
  use Ecto.Migration

  def change do
    create table(:exports__documents) do
      add :name, :string, null: false
      add :type, :string, null: false
      add :notes, :text
      add :category_id, references(:exports__categories, on_delete: :delete_all), null: false
      add :document_id, references(:data__uploads, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:exports__documents, [:category_id])
    create index(:exports__documents, [:document_id])
  end
end
