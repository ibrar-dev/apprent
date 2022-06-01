defmodule Admins.Repo.Migrations.CreateAdmins do
  use Ecto.Migration

  def change do
    execute("CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\" WITH SCHEMA public")
    execute("CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public")

    create table(:admins__admins) do
      add(:email, :citext, null: false)
      add(:name, :string, null: false)
      add(:username, :citext, null: false)
      add(:password_hash, :string, null: true)
      add(:uuid, :uuid, default: fragment("uuid_generate_v4()"), null: false)
      add :roles, {:array, :string}, null: false, default: "{Admin}"
      timestamps()
    end

    create(unique_index(:admins__admins, [:uuid]))
    create(unique_index(:admins__admins, [:email]))
    create(unique_index(:admins__admins, [:username]))
  end
end
