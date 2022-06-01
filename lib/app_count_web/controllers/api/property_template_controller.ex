defmodule AppCountWeb.API.PropertyTemplateController do
  use AppCountWeb, :controller
  alias AppCount.Messaging

  def index(conn, %{"admin" => _}) do
    json(conn, Messaging.list_property_templates(conn.assigns.admin))
  end

  def show(conn, %{"id" => id}) do
    json(conn, Messaging.templates_properties(id))
  end

  def create(conn, %{"property_template" => params}) do
    Messaging.create_property_template(conn.assigns.admin, params)
    json(conn, %{})
  end

  def update(conn, %{"id" => id, "mail_template" => params}) do
    Messaging.edit_template(id, params, conn.assigns.admin.name)
    json(conn, %{})
  end

  def delete(conn, %{"id" => id}) do
    Messaging.delete_all_templates(id)
    json(conn, %{})
  end
end
