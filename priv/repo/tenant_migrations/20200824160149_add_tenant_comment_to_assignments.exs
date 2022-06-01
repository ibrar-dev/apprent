defmodule AppCount.Repo.Migrations.AddTenantCommentToAssignments do
  use Ecto.Migration

  def change do
    alter table("maintenance__assignments") do
      add :tenant_comment, :text, default: ""
    end
  end
end
