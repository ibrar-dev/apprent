defmodule AppCountWeb.API.OrderController do
  use AppCountWeb, :controller
  alias AppCount.Maintenance
  alias AppCount.Core.ClientSchema

  ## NEW WORK ORDER INDEX FUNCTION, TAKES IN MULTIPLE PROPERTIES
  def index(conn, %{"new" => _, "properties" => property_ids, "dates" => dates}) do
    ids =
      property_ids
      |> String.split(",")
      |> Enum.map(fn id -> String.to_integer(id) end)

    data =
      maintenance(conn).list_orders_new(
        conn.assigns.admin,
        dates,
        ClientSchema.new(conn.assigns.client_schema, ids)
      )

    json(conn, data)
  end

  def index(conn, %{"type" => type, "property_id" => property_id}) do
    list_of_orders_type =
      conn.assigns.client_schema
      |> ClientSchema.new(property_id)
      |> maintenance(conn).list_orders_type(type)

    json(conn, list_of_orders_type)
  end

  def show(conn, %{"id" => id, "tenantsOrders" => _}) do
    json(
      conn,
      maintenance(conn).get_tenants_orders(ClientSchema.new(conn.assigns.client_schema, id))
    )
  end

  def show(conn, %{"id" => id, "new" => _}) do
    order_info =
      conn.assigns.admin
      |> AppCount.Core.ClientSchema.new()
      |> maintenance(conn).show_order(id)

    json(conn, order_info)
  end

  def show(conn, %{"id" => id}) do
    json(conn, maintenance(conn).get_order(conn.assigns.admin, id))
  end

  def create(conn, %{"work_order" => work_order}) do
    map = %{"created_by" => conn.assigns.admin.name}
    work_order = Map.merge(map, work_order)

    Maintenance.create_order(
      conn.assigns.admin.id,
      ClientSchema.new(conn.assigns.client_schema, work_order)
    )

    json(conn, %{})
  end

  def create(conn, %{"workOrder" => work_order}) do
    map = %{"created_by" => conn.assigns.admin.name}
    work_order = Map.merge(map, work_order)

    case Maintenance.create_order(
           conn.assigns.admin.id,
           ClientSchema.new(conn.assigns.client_schema, work_order)
         ) do
      {:ok, order} ->
        json(conn, %{order_data: %{id: order.id, ticket: order.ticket}})

      {:error, %{errors: errors}} ->
        message =
          Enum.reduce(errors, "", fn e, acc -> normalize_message(e) <> acc end)
          |> String.slice(0..-2)

        conn
        |> put_status(422)
        |> json(message)
    end
  end

  def create(conn, %{"email_resident" => params}) do
    maintenance(conn).email_resident(conn.assigns.admin.id, params)
    json(conn, %{})
  end

  def create(
        conn,
        %{"snapshot" => %{"start_date" => start_date, "end_date" => end_date}} = _params
      ) do
    {:ok, timex_start_date} = Timex.parse(start_date, "{ISO:Extended:Z}")
    {:ok, timex_end_date} = Timex.parse(end_date, "{ISO:Extended:Z}")

    json(
      conn,
      maintenance(conn).daily_snapshot(conn.assigns.admin, timex_start_date, timex_end_date)
    )
  end

  def create(conn, %{"snapshot" => date}) do
    {:ok, timex_date} = Timex.parse(date, "{ISO:Extended:Z}")
    json(conn, maintenance(conn).admin_daily_snapshot(conn.assigns.admin, timex_date))
  end

  def update(conn, %{"id" => id, "reason" => reason}) do
    maintenance(conn).delete_order(conn.assigns.admin.name, id, reason)
    json(conn, %{})
  end

  def update(conn, %{"id" => id, "workOrder" => params}) do
    wrapped_params = ClientSchema.new("dasmen", params)
    maintenance(conn).update_order(id, wrapped_params)
    json(conn, %{})
  end

  defp normalize_message({f, {e, _}}) do
    "#{f} #{e},"
    |> String.replace(~r/_id/, "")
    |> String.replace(~r/_/, " ")
    |> String.capitalize()
  end
end
