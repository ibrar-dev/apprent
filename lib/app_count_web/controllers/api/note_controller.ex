defmodule AppCountWeb.API.NoteController do
  use AppCountWeb, :controller
  alias AppCount.Maintenance
  alias AppCount.Core.ClientSchema

  def index(conn, %{"note" => note, "getCat" => _}) do
    json(conn, Maintenance.get_best_cat_id(note))
  end

  def index(conn, %{"note" => note, "getUpdatedCat" => _}) do
    json(conn, Maintenance.get_best_cat_ids(note))
  end

  def index(conn, %{"order_id" => order_id, "fetch_notes" => _, "order_type" => "Maintenance"}) do
    json(
      conn,
      maintenance(conn).get_maintenance_notes(
        ClientSchema.new(conn.assigns.client_schema, order_id),
        :private
      )
    )
  end

  def index(conn, %{"order_id" => order_id, "fetch_notes" => _, "order_type" => "Vendor"}) do
    json(conn, maintenance(conn).get_vendor_notes(order_id))
  end

  def create(conn, %{"newNote" => params}) do
    params =
      params
      |> Map.merge(%{"admin_id" => conn.assigns.admin.id})
      |> to_atoms

    ClientSchema.new(conn.assigns.client_schema, params)
    |> Maintenance.create_note()
    |> handle_error(conn)
  end

  def create(conn, %{"notes" => params}) do
    params = %{
      admin_id: conn.assigns.admin.id,
      order_id: params["order_id"],
      text: params["noteText"],
      image: params["image"]
    }

    ClientSchema.new(conn.assigns.client_schema, params)
    |> Maintenance.create_note()

    json(conn, %{})
  end

  def delete(conn, %{"id" => id}) do
    Maintenance.delete_note(id)
    json(conn, %{})
  end
end
