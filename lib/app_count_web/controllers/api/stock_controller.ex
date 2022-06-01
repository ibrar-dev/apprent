defmodule AppCountWeb.API.StockController do
  use AppCountWeb, :controller
  alias AppCount.Materials
  alias AppCount.Core.ClientSchema

  def index(conn, _) do
    stocks = Materials.list_stocks(conn.assigns.admin)

    properties =
      AppCount.Properties.list_properties(
        ClientSchema.new(conn.assigns.admin.client_schema, conn.assigns.admin),
        :min
      )

    json(conn, %{stocks: stocks, properties: properties})
  end

  def show(conn, %{"id" => id, "stock" => _}) do
    json(conn, Materials.show_stock(id))
  end

  def show(conn, %{"id" => id, "materials" => _}) do
    json(conn, Materials.show_stock_materials(id))
  end

  def create(conn, %{"stock" => params}) do
    Materials.create_stock(params)
    json(conn, %{})
  end

  def create(conn, %{"import_csv" => %{"name" => filename, "stock_id" => stock_id}}) do
    Materials.import_csv(filename, stock_id)
    json(conn, %{})
  end

  def update(conn, %{"id" => id, "stock" => params}) do
    Materials.update_stock(id, params)
    json(conn, %{})
  end

  def delete(conn, %{"id" => id}) do
    Materials.delete_stock(id)
    json(conn, %{})
  end
end
