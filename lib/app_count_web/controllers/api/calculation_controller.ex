defmodule AppCountWeb.API.CalculationController do
  use AppCountWeb, :controller
  alias AppCount.Properties

  def index(conn, %{"trend" => days, "property_id" => property_id}) do
    json(
      conn,
      Properties.calculate_trend([property_id], String.to_integer(days))
    )
  end
end
