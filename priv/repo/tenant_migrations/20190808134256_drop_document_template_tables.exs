defmodule AppCount.Repo.Migrations.DropDocumentTemplateTables do
  use Ecto.Migration

  def up do
    drop table(:properties__property_documents)
    drop table(:properties__document_templates)
  end

  def down do
    create table(:properties__property_documents)
    create table(:properties__document_templates)
  end
end
