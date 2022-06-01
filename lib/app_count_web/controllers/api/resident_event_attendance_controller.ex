defmodule AppCountWeb.API.ResidentEventAttendanceController do
  use AppCountWeb, :controller
  alias AppCount.Properties

  def create(conn, %{"resident_event_attendance" => params}) do
    case Properties.create_resident_event_attendance(params) do
      {:ok, _} -> json(conn, %{})
    end
  end
end
