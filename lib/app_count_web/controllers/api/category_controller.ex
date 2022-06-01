defmodule AppCountWeb.API.CategoryController do
  use AppCountWeb, :controller
  alias AppCount.Maintenance

  def index(conn, %{"assign" => _}) do
    json(conn, Maintenance.list_categories({:flat, conn.assigns.client_schema}))
  end

  def index(conn, _params) do
    render(conn, "index.json", categories: Maintenance.list_categories(conn.assigns.client_schema))
  end

  def create(conn, %{"category" => params}) do
    Maintenance.create_category({params, conn.assigns.client_schema})

    json(conn, %{})
  end

  def update(conn, %{"id" => id, "category" => params}) do
    Maintenance.update_category(id, {params, conn.assigns.client_schema})
    json(conn, %{})
  end

  def delete(conn, %{"id" => id}) do
    Maintenance.delete_category({id, conn.assigns.client_schema})
    json(conn, %{})
  end
end
