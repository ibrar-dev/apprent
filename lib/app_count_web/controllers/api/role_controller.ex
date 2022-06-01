defmodule AppCountWeb.API.RoleController do
  use AppCountWeb, :controller
  alias AppCount.Admins.RoleRepo

  def index(conn, %{"tree" => _}) do
    modules =
      conn.assigns.user.features
      |> Enum.reduce([], fn {module_name, enabled}, acc ->
        if enabled, do: ["#{module_name}" | acc], else: acc
      end)

    json(conn, AppCountAuth.Modules.Resources.resource_tree(modules))
  end

  def index(conn, _params) do
    roles =
      AppCount.Core.ClientSchema.new(conn.assigns.user.client_schema, nil)
      |> AppCount.Admins.Utils.Roles.list_roles()

    json(conn, roles)
  end

  def create(conn, %{"role" => params}) do
    RoleRepo.insert(params, prefix: conn.assigns.user.client_schema)
    |> handle_error(conn)
  end

  def update(conn, %{"id" => id, "role" => params}) do
    AppCount.Core.ClientSchema.new(conn.assigns.user.client_schema, id)
    |> AppCount.Admins.Utils.Roles.update_role(params)
    |> handle_error(conn)
  end

  def delete(conn, %{"id" => id}) do
    id
    |> String.to_integer()
    |> RoleRepo.delete(prefix: conn.assigns.user.client_schema)
    |> handle_error(conn)
  end
end
