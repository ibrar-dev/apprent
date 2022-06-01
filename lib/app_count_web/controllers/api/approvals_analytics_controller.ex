defmodule AppCountWeb.API.ApprovalsAnalyticsController do
  use AppCountWeb, :controller
  alias AppCount.Approvals.Utils.ApprovalsQueries.Analytics
  alias AppCount.Core.ClientSchema

  def index(conn, %{"infoBox" => _, "properties" => property_ids, "type" => type}) do
    json(
      conn,
      Analytics.get_analytics(
        ClientSchema.new(conn.assigns.client_schema, String.split(property_ids, ",")),
        type
      )
    )
  end

  def index(conn, %{"chart" => _, "properties" => property_ids, "dates" => dates}) do
    json(conn, Analytics.get_chart(String.split(property_ids, ","), dates))
  end
end
