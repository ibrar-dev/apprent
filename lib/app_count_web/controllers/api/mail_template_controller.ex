defmodule AppCountWeb.API.MailTemplateController do
  use AppCountWeb, :controller
  alias AppCount.Messaging

  def index(conn, %{}) do
    json(conn, Messaging.list_templates())
  end

  def index(conn, %{"admin" => _}) do
    json(conn, Messaging.list_templates(conn.assigns.admin))
  end

  def create(conn, %{"mail_template" => params}) do
    Messaging.create_template(conn.assigns.admin.name, params)
    json(conn, %{})
  end

  def update(conn, %{"id" => id, "mail_template" => params}) do
    Messaging.edit_template(id, params, conn.assigns.admin.name)
    json(conn, %{})
  end

  def delete(conn, %{"id" => id}) do
    Messaging.delete_template(id)
    json(conn, %{})
  end
end
