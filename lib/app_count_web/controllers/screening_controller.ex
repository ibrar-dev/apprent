defmodule AppCountWeb.ScreeningController do
  use AppCountWeb, :controller
  alias AppCount.Leases

  def show(conn, %{"id" => id}) do
    conn
    |> put_layout(false)
    |> render("letter.html", Leases.adverse_action_params(id))
  end
end
