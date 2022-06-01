defmodule AppCount.Repo.Migrations.CreatePropertiesPropertyDocuments do
  use Ecto.Migration

  def change do
    create table(:properties__property_documents) do
      add :property_id, references(:properties__properties, on_delete: :delete_all), null: false
      add :template_id, references(:properties__document_templates, on_delete: :delete_all), null: false
      timestamps()
    end
    create unique_index(:properties__property_documents, [:property_id, :template_id])
  end
end
