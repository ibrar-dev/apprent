defmodule AppCount.Repo.Migrations.CreatePropertiesDocuments do
  use Ecto.Migration

  def change do
    create table(:properties__documents) do
      add :url, :string, null: false
      add :name, :string, null: false
      add :tenant_id, references(:properties__tenants, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:properties__documents, [:tenant_id])
  end
end
