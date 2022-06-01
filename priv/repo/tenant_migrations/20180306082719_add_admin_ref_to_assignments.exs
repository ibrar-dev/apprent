defmodule AppCount.Repo.Migrations.AddAdminRefToAssignments do
  use Ecto.Migration

  def change do
    alter table(:maintenance__assignments) do
      add :admin_id, references(:admins__admins, on_delete: :nilify_all)
    end
  end
end
