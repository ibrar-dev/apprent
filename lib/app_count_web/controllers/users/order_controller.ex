defmodule AppCountWeb.Users.OrderController do
  use AppCountWeb.Users, :controller
  alias AppCount.Accounts
  alias AppCount.Maintenance
  alias AppCount.Core.ClientSchema

  def index(conn, _params) do
    orders =
      Accounts.get_orders(ClientSchema.new(conn.assigns.client_schema, conn.assigns.user.id))

    render(conn, "index.html", orders: orders)
  end

  def new(conn, _params) do
    order = Ecto.Changeset.change(%Maintenance.Order{notes: []})
    categories = Maintenance.list_categories(conn.assigns.client_schema)

    orders =
      Accounts.get_orders(ClientSchema.new(conn.assigns.client_schema, conn.assigns.user.id))

    render(conn, "new.html", order: order, categories: categories, orders: orders)
  end

  def edit(conn, %{"id" => id}) do
    order =
      Accounts.get_order(conn.assigns.user.id, id)
      |> Ecto.Changeset.change()

    categories = Maintenance.list_categories(conn.assigns.client_schema)

    render(conn, "edit.html", order: order, categories: categories)
  end

  def create(conn, %{"order" => params}) do
    cat_id = params["category_id"] || Maintenance.get_best_cat_id(params["notes"])
    params = Map.put(params, "category_id", cat_id)

    case Accounts.create_order(conn.assigns.user.id, params) do
      {:ok, _} ->
        conn
        |> put_flash(:success, "Order Created")
        |> redirect(to: Routes.user_order_path(conn, :index))

      {:error, %{errors: [{f, {error, _}}]}} ->
        field =
          String.replace("#{f}", ~r/_id/, "")
          |> String.capitalize()

        conn
        |> put_flash(:error, "#{field} #{error}")
        |> redirect(to: Routes.user_order_path(conn, :new))
    end
  end

  def update(conn, %{"id" => id, "order" => params}) do
    case Accounts.update_order(conn.assigns.user.id, id, params) do
      {:ok, _} ->
        conn
        |> put_flash(:success, "Order Updated")
        |> redirect(to: Routes.user_order_path(conn, :index))

      {:error, %{errors: [{f, {error, _}}]}} ->
        field =
          String.replace("#{f}", ~r/_id/, "")
          |> String.capitalize()

        conn
        |> put_flash(:error, "#{field} #{error}")
        |> redirect(to: Routes.user_order_path(conn, :edit, id))
    end
  end

  def delete(conn, %{"id" => id}) do
    Accounts.delete_order(conn.assigns.user.id, id)

    conn
    |> put_flash(:success, "Order Deleted")
    |> redirect(to: Routes.user_order_path(conn, :index))
  end
end
