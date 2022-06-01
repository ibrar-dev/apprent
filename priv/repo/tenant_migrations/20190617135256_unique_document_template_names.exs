defmodule AppCount.Repo.Migrations.UniqueDocumentTemplateNames do
  use Ecto.Migration

  def change do
    create unique_index(:properties__document_templates, [:name])
  end
end
