defmodule AppCount.Repo.Migrations.CreatePropertiesAdminDocuments do
  use Ecto.Migration

  def change do
    drop_if_exists table(:properties__admin_documents)
    create table(:properties__admin_documents) do
      add :name, :string, null: false
      add :creator, :string, null: false
      add :type, :string, null: false
      add :document_id, references(:data__uploads, on_delete: :nilify_all)

      timestamps()
    end

  end
end
