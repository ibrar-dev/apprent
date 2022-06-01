defmodule AppCountWeb.API.WorkOrderCategoryController do
  use AppCountWeb, :controller

  authorize(["Super Admin"])

  def index(conn, _params) do
    json(conn, maintenance(conn).list_categories())
  end

  def create(conn, %{"category" => params}) do
    maintenance(conn).create_category(params)
    json(conn, %{})
  end

  def update(conn, %{"id" => id, "category" => params}) do
    maintenance(conn).update_category(id, params)
    json(conn, %{})
  end

  def update(conn, %{"id" => id, "transfer" => to_id}) do
    maintenance(conn).transfer(id, to_id)
    json(conn, %{})
  end

  def delete(conn, %{"id" => id}) do
    maintenance(conn).delete_category(id)
    json(conn, %{})
  end
end
