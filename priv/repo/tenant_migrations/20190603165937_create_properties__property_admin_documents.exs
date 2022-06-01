defmodule AppCount.Repo.Migrations.CreatePropertiesPropertyAdminDocuments do
  use Ecto.Migration

  def change do
    create table(:properties__property_admin_documents) do
      add :property_id, references(:properties__properties, on_delete: :delete_all), null: false
      add :admin_document_id, references(:properties__admin_documents, on_delete: :delete_all), null: false

      timestamps()
    end
    create unique_index(:properties__property_admin_documents, [:property_id, :admin_document_id])
  end
end
