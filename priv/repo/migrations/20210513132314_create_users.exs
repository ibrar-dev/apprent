defmodule AppCount.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    execute("CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public")
    create table(:users) do
      add :type, :string, null: false
      add :username, :citext, null: false
      add :password_hash, :string, null: false
      add :tenant_account_id, :bigint, null: false
      add :client_id, references(:clients, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:users, [:client_id])
    create unique_index(:users, [:username, :type])
  end
end
