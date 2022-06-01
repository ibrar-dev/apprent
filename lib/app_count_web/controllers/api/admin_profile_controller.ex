defmodule AppCountWeb.API.AdminProfileController do
  use AppCountWeb, :controller
  alias AppCount.Admins
  alias AppCount.Core.ClientSchema

  def create(conn, %{"admin_profile" => params}) do
    ClientSchema.new(conn.assigns.client_schema, params)
    |> Admins.create_profile()

    json(conn, %{})
  end

  def update(conn, %{"id" => id, "admin_profile" => params}) do
    ClientSchema.new(conn.assigns.client_schema, id)
    |> Admins.update_profile(params)

    json(conn, %{})
  end

  def delete(conn, %{"id" => id}) do
    Admins.delete_profile(conn.assigns.admin, ClientSchema.new(conn.assigns.client_schema, id))
    json(conn, %{})
  end
end
