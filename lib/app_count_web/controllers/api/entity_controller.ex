defmodule AppCountWeb.API.EntityController do
  # an Entity is a Region which contains 1 or more Properties
  use AppCountWeb, :controller
  alias AppCount.Admins
  alias AppCount.Core.ClientSchema

  def index(conn, _params) do
    render(conn, "index.json",
      entities: Admins.list_entities(ClientSchema.new(conn.assigns.client_schema))
    )
  end

  def create(conn, params) do
    Admins.create_entity(ClientSchema.new(conn.assigns.client_schema, params))
    json(conn, %{})
  end

  def update(conn, %{"id" => id, "entity" => params}) do
    Admins.update_entity(id, ClientSchema.new(conn.assigns.client_schema, params))
    json(conn, %{})
  end

  def update(conn, %{"id" => id, "admin_id" => admin_id, "attach" => true}) do
    Admins.attach_admin(ClientSchema.new(conn.assigns.client_schema, id), admin_id)
    json(conn, %{})
  end

  def update(conn, %{"id" => id, "admin_id" => admin_id, "attach" => false}) do
    Admins.detach_admin(ClientSchema.new(conn.assigns.client_schema, id), admin_id)
    json(conn, %{})
  end

  def update(conn, %{"id" => id, "property_id" => property_id, "attach" => true}) do
    Admins.attach_property_to_entity(
      ClientSchema.new(conn.assigns.client_schema, id),
      property_id
    )

    json(conn, %{})
  end

  def update(conn, %{"id" => id, "property_id" => property_id, "detach" => true}) do
    Admins.detach_property_from_entity(
      ClientSchema.new(conn.assigns.client_schema, id),
      property_id
    )

    json(conn, %{})
  end

  def delete(conn, %{"id" => id}) do
    Admins.delete_entity(ClientSchema.new(conn.assigns.client_schema, id))
    json(conn, %{})
  end
end
