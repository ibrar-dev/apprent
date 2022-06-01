defmodule AppCountWeb.Users.PropertyController do
  use AppCountWeb.Users, :controller
  alias AppCount.Properties
  require Logger
  use AppCount.Decimal

  def index(conn, _params) do
    try do
      _property_info =
        conn.assigns.user.property.id
        |> Properties.property_info()
    rescue
      # error handling here
      error ->
        Logger.error(inspect(error))

        conn
        |> put_status(:not_found)
        |> put_layout(false)
        |> render("not_found.html")
    else
      property_info ->
        render(
          conn,
          "index.html",
          property_info: property_info
        )
    end
  end
end
