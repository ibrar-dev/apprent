defmodule AppCountWeb.Users.API.V1.OrderController do
  use AppCountWeb.Users, :controller
  alias AppCount.Accounts
  alias AppCount.Maintenance
  alias AppCount.Core.ClientSchema

  def index(conn, _) do
    tenants_order =
      Maintenance.get_tenants_orders(
        # no key found in: conn.assigns.client_schema,
        # so using "dasmen" so that it stops crashing in production.
        ClientSchema.new("dasmen", conn.assigns.user.id)
      )

    json(conn, tenants_order)
  end

  def create(conn, %{"order" => params}) do
    cat_id = Maintenance.get_best_cat_id(params["category_id"])
    params = Map.put(params, "category_id", cat_id)

    Accounts.create_order(conn.assigns.user.id, params)
    |> handle_error(conn)
  end

  def show(conn, %{"id" => id}) do
    prop_id = conn.assigns.user.property.id
    json(conn, Maintenance.get_order_tenant(prop_id, id))
  end

  def update(conn, %{"id" => id, "order" => params}) do
    case Accounts.update_order(conn.assigns.user.id, id, params) do
      {:ok, _} -> safe_json(conn, %{})
    end
  end

  def update(conn, %{"id" => id, "cancel" => _}) do
    params = %{
      "cancellation" => %{
        "time" => AppCount.current_time(),
        "admin" => conn.assigns.user.name,
        "reason" => "Resident cancellation"
      }
    }

    case Accounts.update_order(conn.assigns.user.id, id, params) do
      {:ok, _} -> safe_json(conn, %{})
    end
  end

  def update(conn, %{"rating_obj" => rating_obj}) do
    id = rating_obj["id"]
    rate = rating_obj["rating"]

    case Maintenance.rate_assignment(id, rate) do
      {:ok, _} -> safe_json(conn, %{})
    end
  end

  def update(conn, %{"assign" => assign}) do
    assignment = assign["assignment"]
    note = assign["note"]
    Maintenance.resident_callback_assignment(assignment["id"], note)
    json(conn, %{})
  end

  def delete(conn, %{"id" => id}) do
    Accounts.delete_order(conn.assigns.user.id, id)
    json(conn, %{})
  end
end
