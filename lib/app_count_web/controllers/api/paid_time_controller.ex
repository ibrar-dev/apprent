defmodule AppCountWeb.API.PaidTimeController do
  use AppCountWeb, :controller
  alias AppCount.Maintenance

  def index(conn, _) do
    json(conn, Maintenance.list_paid_times(conn.assigns.admin))
  end

  def create(conn, %{"paidTime" => params}) do
    Maintenance.create_paid_time(params)
    json(conn, %{})
  end

  def update(conn, %{"id" => id, "paidTime" => params}) do
    Maintenance.update_paid_time(id, params)
    json(conn, %{})
  end
end
