defmodule AppCountWeb.API.AdminController do
  use AppCountWeb, :controller
  alias AppCount.Admins.Admin
  alias AppCount.Core.ClientSchema

  authorize([], show: ["Admin"])

  def index(conn, %{"fetchTechs" => _}) do
    json(conn, admins(conn).list_tech_admins(ClientSchema.new(conn.assigns.admin)))
  end

  def index(conn, %{"fetchEmployees" => _}) do
    if MapSet.member?(conn.assigns.admin.roles, "Regional") or
         MapSet.member?(conn.assigns.admin.roles, "Super Admin") do
      json(
        conn,
        admins(conn).list_admins(ClientSchema.new(conn.assigns.client_schema, conn.assigns.admin))
      )
    end
  end

  def index(conn, _params) do
    json(conn, admins(conn).list_admins(ClientSchema.new(conn.assigns.client_schema)))
  end

  def show(conn, %{"id" => id}) do
    json(conn, admins(conn).get_admin!(ClientSchema.new(conn.assigns.client_schema, id)))
  end

  #  def show(conn, %{"id" => id}) do
  #    admin = Admins.get_admin!(id)
  #    render(conn, "admins.json", admin: admin)
  #  end

  def create(conn, %{"admin" => params}) do
    json(conn, params)

    case admins(conn).create_admin(
           ClientSchema.new(
             conn.assigns.client_schema,
             params
           )
         ) do
      {:ok, %Admin{} = admin} ->
        s_json(conn, admin)

      {:error, changeset} ->
        conn
        |> put_status(422)
        |> render("error.json", %{changeset: changeset})
    end
  end

  def update(conn, %{
        "id" => id,
        "admin" => %{"active" => activity_status, "bounce" => bounce_status}
      }) do
    case admins(conn).update_admin(
           id,
           ClientSchema.new(
             conn.assigns.client_schema,
             %{active: activity_status}
           )
         ) do
      {:ok, admin} ->
        admins(conn).bounce_admin_email(id, bounce_status)
        s_json(conn, admin)

      {:error, changeset} ->
        conn
        |> put_status(422)
        |> render("error.json", %{errors: changeset.errors})
    end
  end

  def update(conn, %{"id" => id, "admin" => params}) do
    case admins(conn).update_admin(
           id,
           ClientSchema.new(
             conn.assigns.client_schema,
             params
           )
         ) do
      {:ok, admin} ->
        s_json(conn, admin)

      {:error, changeset} ->
        conn
        |> put_status(422)
        |> render("error.json", %{errors: changeset.errors})
    end
  end

  def delete(conn, %{"id" => id}) do
    admins(conn).delete_admin(
      conn.assigns.admin,
      ClientSchema.new(
        conn.assigns.client_schema,
        id
      )
    )

    json(conn, %{success: true})
  end
end
