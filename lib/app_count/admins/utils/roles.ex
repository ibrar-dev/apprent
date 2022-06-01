defmodule AppCount.Admins.Utils.Roles do
  alias AppCount.Admins.AdminRepo
  alias AppCount.Repo
  alias AppCount.Admins.Role
  alias AppCount.Core.ClientSchema

  def list_roles(%ClientSchema{name: client_schema}) do
    AppCount.Admins.RoleRepo.all(prefix: client_schema)
    |> Enum.map(&Map.take(&1, [:id, :name, :permissions]))
  end

  def collect_admin_roles(%AppCount.Admins.Admin{} = admin) do
    admin
    |> Repo.preload(:custom_roles, prefix: admin.__meta__.prefix)
    |> Map.get(:custom_roles)
    |> squash_permissions
  end

  def collect_admin_roles(%ClientSchema{name: client_schema, attrs: admin_id}), do:
    collect_admin_roles(AdminRepo.get(admin_id, prefix: client_schema))

  def update_role(%ClientSchema{name: client_schema, attrs: id}, params) do
    Repo.get(Role, id, prefix: client_schema)
    |> Role.changeset(params)
    |> Repo.update(prefix: client_schema)
  end

  defp squash_permissions([first_role | rest]) do
    Enum.reduce(rest, first_role.permissions, fn role, acc ->
      Map.merge(role.permissions, acc, &merge_permission/3)
    end)
  end

  defp merge_permission(_, :write, :read), do: :write
  defp merge_permission(_, :read, :write), do: :write
  defp merge_permission(_, action, _), do: action
end
