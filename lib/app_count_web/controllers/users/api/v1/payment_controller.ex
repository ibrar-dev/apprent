defmodule AppCountWeb.Users.API.V1.PaymentController do
  use AppCountWeb.Users, :controller

  def index(conn, _) do
    user_id = conn.assigns.user.id
    client_schema = conn.assigns.user.client_schema

    accts_boundary = accounts_boundary(conn)

    billing_info =
      AppCount.Core.ClientSchema.new(client_schema, user_id)
      |> accts_boundary.user_balance()

    lock_info =
      AppCount.Core.ClientSchema.new(client_schema, conn.assigns.user.account_id)
      |> accts_boundary.account_lock_exists?()

    json(
      conn,
      %{
        payments: accts_boundary.list_payments(user_id),
        billing_info: billing_info,
        block_online_payments: lock_info
      }
    )
  end

  def create(conn, _params) do
    conn
    |> put_status(400)
    |> json(%{error: "Please update the AppRent app to the latest version and try again."})
  end
end
