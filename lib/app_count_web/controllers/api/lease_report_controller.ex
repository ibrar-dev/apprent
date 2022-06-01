defmodule AppCountWeb.API.LeaseReportController do
  use AppCountWeb, :controller
  alias AppCount.Leases

  def index(conn, %{
        "property_id" => property_id,
        "start_date" => start_date,
        "end_date" => end_date
      }) do
    start_date = Timex.parse!(start_date, "{M}/{D}/{YYYY}")
    end_date = Timex.parse!(end_date, "{M}/{D}/{YYYY}")
    json(conn, Leases.get_leases(property_id, start_date, end_date))
  end
end
