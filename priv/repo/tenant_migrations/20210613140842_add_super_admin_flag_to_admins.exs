defmodule AppCount.Repo.Migrations.AddSuperAdminFlagToAdmins do
  use Ecto.Migration

  def change do
    alter table(:admins__admins) do
      add :is_super_admin, :boolean, default: false, null: false
    end
  end
end
