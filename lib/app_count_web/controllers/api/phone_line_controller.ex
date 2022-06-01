defmodule AppCountWeb.API.PhoneLineController do
  use AppCountWeb, :controller
  alias AppCount.Properties

  def index(conn, %{"property_id" => property_id}) do
    json(conn, Properties.list_phone_lines(property_id))
  end

  def create(conn, %{"phone_line" => params}) do
    Properties.create_phone_line(params)
    |> handle_error(conn)
  end

  def update(conn, %{"id" => id, "phone_line" => params}) do
    Properties.update_phone_line(id, params)
    |> handle_error(conn)
  end

  def delete(conn, %{"id" => id}) do
    Properties.delete_phone_line(id)
    json(conn, %{})
  end
end
