defmodule AppCountWeb.WorkOrderCategoryController do
  use AppCountWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html", %{title: "Maintenance Categories"})
  end
end
