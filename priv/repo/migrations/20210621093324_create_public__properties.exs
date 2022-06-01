defmodule AppCount.Repo.Migrations.CreatePublicProperties do
  use Ecto.Migration

  def change do
    create table(:properties) do
      add :code, :string, null: false
      add :client_id, references(:clients, on_delete: :delete_all), null: false
      add :schema_id, :bigint, null: false

      timestamps()
    end

    create index(:properties, [:client_id])
    create unique_index(:properties, [:code])
    create unique_index(:properties, [:schema_id, :client_id])
  end
end
