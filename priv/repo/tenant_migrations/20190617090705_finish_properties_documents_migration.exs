defmodule AppCount.Repo.Migrations.FinishPropertiesDocumentsMigration do
  use Ecto.Migration

  def change do
    alter table(:properties__documents) do
      remove :url
      modify :document_id, :bigint, null: false
    end
  end
end
