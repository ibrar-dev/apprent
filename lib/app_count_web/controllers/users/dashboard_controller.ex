defmodule AppCountWeb.Users.DashboardController do
  use AppCountWeb.Users, :controller
  # Ideally everything here should go through AppCount.Accounts
  # But that is outside the scope of this HB issue.
  alias AppCount.Accounts
  alias AppCount.Properties
  alias AppCount.Rewards
  alias AppCount.Core.ClientSchema

  def index(conn, _params) do
    {_, points} = Rewards.tenant_history(conn.assigns.user.id)

    active_lock =
      ClientSchema.new(conn.assigns.client_schema, conn.assigns.user.account_id)
      |> Accounts.active_lock()

    user = conn.assigns.user

    conn
    |> maybe_put_lock_message(active_lock)
    |> render(
      "index.html",
      payment_sources: Accounts.list_payment_sources(conn.assigns.user.id),
      unit_info: Accounts.unit_info(user.id),
      billing_info: Accounts.user_balance(ClientSchema.new(user.client_schema, user.id)),
      payments: Accounts.list_payments(conn.assigns.user.id, 5),
      active_lock: active_lock,
      property_info: conn.assigns.user.property,
      packages: Properties.list_resident_packages(conn.assigns.user.id),
      orders:
        Accounts.get_orders(ClientSchema.new(conn.assigns.client_schema, conn.assigns.user.id)),
      autopay: Accounts.get_autopay_info(conn.assigns.user.account_id),
      agreement_text:
        Properties.agreement_text_for(
          ClientSchema.new(conn.assigns.user.client_schema, conn.assigns.user.property)
        ),
      points: points
    )
  end

  defp maybe_put_lock_message(conn, %AppCount.Accounts.Lock{enabled: true, reason: reason}) do
    conn
    |> put_flash(:error, "Your account has been locked. Reason: #{reason}.")
  end

  defp maybe_put_lock_message(conn, _) do
    conn
  end
end
