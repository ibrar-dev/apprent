defmodule AppCountWeb.API.ApplicantController do
  use AppCountWeb, :controller
  alias AppCount.RentApply
  authorize(["Admin", "Agent"])

  def show(conn, %{"id" => id}) do
    json(conn, RentApply.get_application_ledger(id))
  end
end
