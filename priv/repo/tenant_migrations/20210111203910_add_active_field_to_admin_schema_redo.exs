defmodule AppCount.Repo.Migrations.AddActiveFieldToAdminSchemaRedo do
  use Ecto.Migration

  def change do
    alter table("admins__admins") do
      add_if_not_exists :active, :boolean, default: true
    end
  end
end
