defmodule AppCountWeb.AdminUserSessionController do
  use AppCountWeb, :controller
  alias AppCount.Core.ClientSchema
  authorize(["Admin", "Agent"] when action in [:show])

  def create(conn, %{"id" => _, "token" => token}) do
    {:ok, user} = AppCountWeb.Token.verify(token)
    token = AppCountWeb.Token.token(user)

    put_session(conn, :user_token, token)
    |> redirect(to: Routes.user_dashboard_path(conn, :index))
  end

  def show(conn, %{"id" => id}) do
    token =
      AppCount.Public.Auth.get_tenant_data(
        "Tenant",
        ClientSchema.new(conn.assigns.user.client_schema, %{tenant_account_id: id, id: nil})
      )
      |> AppCountWeb.Token.token()

    redirect(conn, external: "#{AppCount.namespaced_url(:residents)}/user_accounts/#{id}/#{token}")
  end
end
