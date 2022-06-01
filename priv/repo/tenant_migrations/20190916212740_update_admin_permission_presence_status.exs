defmodule AppCount.Repo.Migrations.UpdateAdminPermissionPresenceStatus do
  use Ecto.Migration

  def change do
    alter table(:purchases__admin_permissions) do
      remove :presence_status
      add :presence_status, :string, default: "available"
    end
  end
end
