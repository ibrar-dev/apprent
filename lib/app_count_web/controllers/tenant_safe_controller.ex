defmodule AppCountWeb.TenantSafeController do
  use AppCountWeb, :controller

  def update(conn, %{"Status" => status_xml}) do
    status_xml
    |> TenantSafe.HandlePostback.handle()
    |> AppCount.Leases.handle_postback()

    json(conn, %{})
  end
end
