defmodule AppCount.Repo.Migrations.CreateAdminsRoles do
  use Ecto.Migration

  def change do
    create table(:admins__roles) do
      add :name, :string, null: false
      add :permissions, :jsonb, null: false, default: "{}"

      timestamps()
    end

  end
end
