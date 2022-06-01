defmodule AppCount.Repo.Migrations.CreateAdminsAdminRoles do
  use Ecto.Migration

  def change do
    create table(:admins__admin_roles) do
      add :admin_id, references(:admins__admins, on_delete: :delete_all), null: false
      add :role_id, references(:admins__roles, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:admins__admin_roles, [:admin_id])
    create index(:admins__admin_roles, [:role_id])
    create unique_index(:admins__admin_roles, [:role_id, :admin_id])
  end
end
