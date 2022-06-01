defmodule AppCount.Repo.Migrations.AddUploadRefToRentApplyDocuments do
  use Ecto.Migration

  def change do
    alter table(:rent_apply__documents) do
      add :url_id, references(:data__uploads, on_delete: :delete_all)
      modify :url, :string, null: true
    end

    create index(:rent_apply__documents, [:url_id])
  end
end
