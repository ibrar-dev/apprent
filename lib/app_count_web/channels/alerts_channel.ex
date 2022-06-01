defmodule AppCountWeb.AlertsChannel do
  use AppCountWeb, :channel

  alias AppCount.Admins
  alias AppCount.Core.ClientSchema

  def join(_topic, _alert, socket) do
    {:ok, %{id: socket.assigns.admin.id}, socket}
  end

  def join("alerts:" <> _, socket) do
    {:ok, socket}
  end

  def send_payload(admin_id, payload, message) do
    AppCountWeb.Endpoint.broadcast("alerts:#{admin_id}", message, payload)
  end

  def alert_notification(admin_id, alert) do
    payload = %{alert: alert} |> AppCount.StructSerialize.serialize()
    send_payload(admin_id, payload, "NEW_ALERT")
  end

  def total_unread_alerts(admin_id, unread_alerts) do
    payload = %{unread: unread_alerts} |> AppCount.StructSerialize.serialize()
    send_payload(admin_id, payload, "UNREAD_ALERTS")
  end

  def total_unread_alerts(admin_id) do
    unread =
      ClientSchema.new("dasmen", admin_id)
      |> Admins.get_total_unread()

    payload = %{unread: unread} |> AppCount.StructSerialize.serialize()
    send_payload(admin_id, payload, "UNREAD_ALERTS")
  end

  def handle_in("UPDATE_TOTAL", _, socket) do
    total_unread_alerts(socket.assigns.admin.id)
    {:noreply, socket}
  end

  def handle_in("FETCH_ALERTS", _, socket) do
    # TODO:SCHEMA
    unread = Admins.get_alerts(ClientSchema.new("dasmen", socket.assigns.admin.id))
    payload = %{unread: unread} |> AppCount.StructSerialize.serialize()
    send_payload(socket.assigns.admin.id, payload, "FETCH_ALERTS")
    {:noreply, socket}
  end

  def handle_in("READ_ALERT", alert_id, socket) do
    ClientSchema.new("dasmen", alert_id)
    |> Admins.read_alert()

    total_unread_alerts(socket.assigns.admin.id)
    handle_in("FETCH_ALERTS", %{}, socket)
    {:noreply, socket}
  end

  def handle_in("UNREAD_ALERT", alert_id, socket) do
    ClientSchema.new("dasmen", alert_id)
    |> Admins.unread_alert()

    total_unread_alerts(socket.assigns.admin.id)
    handle_in("FETCH_ALERTS", %{}, socket)
    {:noreply, socket}
  end

  def handle_in("DELETE_ALERT", alert_id, socket) do
    admin = AppCount.Repo.get(Admins.Admin, socket.assigns.admin.id)

    if MapSet.member?(admin.roles, "Super Admin") or MapSet.member?(admin.roles, "Regional") do
      Admins.delete_alert(alert_id)
    end

    {:noreply, socket}
  end

  def handle_in("FETCH_EMPLOYEES", _admin_id, socket) do
    admin = AppCount.Repo.get(Admins.Admin, socket.assigns.admin.id)

    if MapSet.member?(admin.roles, "Super Admin") or MapSet.member?(admin.roles, "Regional") do
      employees = Admins.list_admins(ClientSchema.new("dasmen", admin))
      payload = %{employees: employees} |> AppCount.StructSerialize.serialize()
      send_payload(admin.id, payload, "EMPLOYEES")
    end

    {:noreply, socket}
  end
end
