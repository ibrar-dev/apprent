defmodule AppCount.Repo.Migrations.CreatePropertiesDocumentTemplates do
  use Ecto.Migration

  def change do
    create table(:properties__document_templates) do
      add :name, :string, null: false
      add :body, :text, null: false
      add :creator, :name, null: false
      timestamps()
    end

  end
end


