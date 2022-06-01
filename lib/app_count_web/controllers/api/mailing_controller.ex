defmodule AppCountWeb.API.MailingController do
  use AppCountWeb, :controller
  alias AppCount.Messaging
  alias AppCount.Core.ClientSchema

  def index(conn, %{"property_id" => property_id, "type" => type}) do
    json(conn, Messaging.get_residents_by_type(conn.assigns.admin, property_id, type))
  end

  def index(conn, %{"type" => type}) do
    json(conn, Messaging.get_residents_by_type(conn.assigns.admin, type))
  end

  def show(conn, %{"id" => property_id}) do
    contents = Messaging.get_residents_csv(property_id)

    send_download(
      conn,
      {:binary, contents},
      content_type: "text/csv",
      filename: "users.csv"
    )
  end

  def create(conn, %{"resident_email" => params}) do
    Messaging.create_mailing(conn.assigns.admin, params)
    json(conn, %{})
  end

  def create(conn, %{"scheduled_email" => params}) do
    Messaging.create_scheduled_mailing(ClientSchema.new(conn.assigns.admin), params)
    json(conn, %{})
  end
end
