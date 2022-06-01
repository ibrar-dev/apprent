defmodule AppCountWeb.API.ToolboxItemController do
  use AppCountWeb, :controller
  alias AppCount.Materials

  authorize(["Property", "Tech", "Regional", "Super Admin"])

  def index(conn, %{"tech_id" => tech_id, "stock_id" => stock_id}) do
    json(conn, Materials.list_items_in_cart(tech_id, stock_id))
  end

  def index(conn, %{"stock_id" => stock_id, "start_date" => start_date, "end_date" => end_date}) do
    {:ok, timex_start_date} = Timex.parse(start_date, "{ISOdate}")
    {:ok, timex_end_date} = Timex.parse(end_date, "{ISOdate}")
    json(conn, Materials.list_ordered_items(stock_id, timex_start_date, timex_end_date))
  end

  def index(conn, %{"tech_id" => tech_id}) do
    json(conn, Materials.list_items_in_toolbox(tech_id))
  end

  def index(conn, %{"stock_id" => stock_id}) do
    json(conn, Materials.list_possible_items(stock_id))
  end

  def create(conn, %{"admin_add" => _, "toolbox" => params}) do
    Materials.admin_add(params, conn.assigns.admin.name)
    json(conn, %{})
  end

  def create(conn, %{"password" => password}) do
    json(conn, Materials.authenticate_tech(password))
  end

  def create(conn, %{"toolbox_item" => params, "adminAdd" => _}) do
    Materials.admin_add_toolbox(params, conn.assigns.admin.name)
    json(conn, %{})
  end

  def create(conn, %{"toolbox_item" => params}) do
    Materials.add_item_to_toolbox(params)
    json(conn, %{})
  end

  def update(conn, %{"id" => tech_id, "stock_id" => stock_id}) do
    Materials.checkout_items_in_toolbox(tech_id, stock_id)
    json(conn, %{})
  end

  def update(conn, %{"id" => id, "return_stock" => stock_id}) do
    Materials.return_item_to_stock(id, stock_id)
    json(conn, %{})
  end

  def update(conn, %{"id" => id, "return_from_cart" => _}) do
    Materials.return_item_from_cart(id)
    json(conn, %{})
  end

  def update(conn, %{"id" => id, "remove_all" => _}) do
    Materials.clear_pending_toolbox(id)
    json(conn, %{})
  end
end
