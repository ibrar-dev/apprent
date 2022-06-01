defmodule AppCount.Repo.Migrations.RenameSchemaToClientSchema do
  use Ecto.Migration

  def change do
    drop_if_exists index(:clients, [:schema])
    rename table(:clients), :schema, to: :client_schema
    create unique_index(:clients, [:client_schema])
  end
end
