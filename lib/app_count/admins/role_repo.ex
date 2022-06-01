defmodule AppCount.Admins.RoleRepo do
  use AppCount.Core.GenericRepo, schema: AppCount.Admins.Role
  alias AppCount.Admins.AdminRole

  def attach_role_to_admin(client_schema, admin, role) do
    %AdminRole{}
    |> AdminRole.changeset(%{admin_id: admin.id, role_id: role.id})
    |> Repo.insert(prefix: client_schema)
  end

  def detach_role_from_admin(client_schema, admin, role) do
    admin_role =
      Repo.get_by(AdminRole, [admin_id: admin.id, role_id: role.id], prefix: client_schema)

    if admin_role, do: Repo.delete(admin_role, prefix: client_schema)
  end
end
