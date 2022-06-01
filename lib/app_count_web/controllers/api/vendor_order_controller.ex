defmodule AppCountWeb.API.VendorOrderController do
  use AppCountWeb, :controller
  alias AppCount.Vendors
  alias AppCount.Core.ClientSchema

  def index(conn, _params) do
    json(conn, Vendors.list_orders(conn.assigns.admin))
  end

  def show(conn, %{"id" => id, "order" => order} = _) do
    if order != "order" do
      list_of_orders =
        conn.assigns.admin
        |> ClientSchema.new()
        |> Vendors.list_orders(id)

      json(conn, list_of_orders)
    else
      order =
        ClientSchema.new(conn.assigns.client_schema, id)
        |> Vendors.get_order()

      json(conn, order)
    end
  end

  def create(conn, %{"orders" => params}) do
    new_params =
      Enum.map(params, fn p ->
        Map.merge(p, %{"admin_id" => conn.assigns.admin.id, "order_id" => p["id"]})
      end)

    res =
      %ClientSchema{
        name: conn.assigns.client_schema,
        attrs: %{orders: new_params}
      }
      |> vendor_order_boundary(conn).create_orders()

    case Enum.all?(res, fn {r, _} -> r == :ok end) do
      true ->
        json(conn, %{})

      _ ->
        conn
        |> put_status(422)
        |> json("Not all orders were successfully outsourced")
    end
  end

  def create(conn, params) do
    new_params = Map.merge(params, %{"admin_id" => conn.assigns.admin.id})
    Vendors.create_order(new_params)
    json(conn, %{})
  end

  def update(conn, %{"id" => id, "vendorOrder" => params}) do
    map = %{"admin" => conn.assigns.admin.name}
    Vendors.update_order(id, Map.merge(params, map))
    json(conn, %{})
  end

  def delete(conn, %{"id" => id}) do
    if MapSet.member?(conn.assigns.admin.roles, "Super Admin") do
      Vendors.delete_order(id)
    end

    json(conn, %{})
  end
end
