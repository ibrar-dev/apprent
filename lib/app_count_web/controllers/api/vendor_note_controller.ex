defmodule AppCountWeb.API.VendorNoteController do
  use AppCountWeb, :controller
  alias AppCount.Vendors

  def create(conn, %{"notes" => params}) do
    %{
      admin_id: conn.assigns.admin.id,
      order_id: params["order_id"],
      text: params["noteText"],
      image: params["image"]
    }
    |> Vendors.create_note()

    json(conn, %{})
  end

  def delete(conn, %{"id" => id}) do
    Vendors.delete_note(id)
    json(conn, %{})
  end
end
