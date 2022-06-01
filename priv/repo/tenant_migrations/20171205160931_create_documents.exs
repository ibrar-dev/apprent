defmodule RentApply.Repo.Migrations.CreateDocuments do
  use Ecto.Migration

  def change do
    create table(:rent_apply__documents) do
      add :type, :string, null: false
      add :url, :string, null: false
      add :application_id, references(:rent_apply__rent_applications, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:rent_apply__documents, [:application_id])
  end
end
