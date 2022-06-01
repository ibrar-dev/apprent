defmodule AppCountWeb.API.PaymentAnalyticsController do
  use AppCountWeb, :controller

  def index(conn, %{"infoBoxes" => _, "properties" => property_ids}) do
    json(
      conn,
      accounting_boundary(conn).info_boxes_payment_analytics(
        String.split(property_ids, ","),
        conn.assigns.client_schema
      )
    )
  end

  def index(conn, %{"charts" => _, "properties" => property_ids, "dates" => dates}) do
    json(
      conn,
      accounting_boundary(conn).charts_payment_analytics(
        String.split(property_ids, ","),
        dates,
        conn.assigns.client_schema
      )
    )
  end
end
