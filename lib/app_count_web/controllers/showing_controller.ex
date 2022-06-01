defmodule AppCountWeb.ShowingController do
  use AppCountWeb, :public_controller
  alias AppCount.Prospects
  alias AppCount.Properties

  def new(conn, %{"property_code" => code}) do
    # TODO:SCHEMA
    case Properties.get_property([code: code], "dasmen") do
      %AppCount.Properties.Property{} = prop ->
        conn
        |> put_layout(false)
        |> render("new.html", property: prop)

      nil ->
        send_resp(conn, 404, "No such property")
    end
  end

  def create(conn, %{"prospect" => prospect, "showing" => showing}) do
    {:ok, prospect} = Prospects.create_prospect(prospect)
    Prospects.create_showing(Map.put(showing, "prospect_id", prospect.id))
    render(conn, "create.html")
  end
end
