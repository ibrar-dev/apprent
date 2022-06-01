defmodule AppCountWeb.Users.PaymentController do
  use AppCountWeb.Users, :controller
  alias AppCount.Accounts
  alias AppCount.Properties
  alias AppCount.Core.ClientSchema

  require Logger

  def index(conn, _params) do
    render(
      conn,
      "index.html",
      user: conn.assigns.user,
      payments: Accounts.list_payments(conn.assigns.user.id),
      payment_sources: Accounts.list_payment_sources(conn.assigns.user.id),
      unit_info: Accounts.unit_info(conn.assigns.user.id),
      billing_info:
        Accounts.user_balance(
          ClientSchema.new(conn.assigns.user.client_schema, conn.assigns.user.id)
        ),
      active_lock:
        Accounts.active_lock(
          ClientSchema.new(conn.assigns.user.client_schema, conn.assigns.user.account_id)
        ),
      property_info: conn.assigns.user.property,
      autopay: Accounts.get_autopay_info(conn.assigns.user.account_id),
      agreement_text:
        Properties.agreement_text_for(
          ClientSchema.new(conn.assigns.user.client_schema, conn.assigns.user.property)
        )
    )
  end

  def create(conn, %{"payment" => params}) do
    %{
      "payment_source_id" => payment_source_id,
      "amount_in_cents" => amount_in_cents,
      "agreement_text" => agreement_text
    } = params

    ip_address = conn.assigns.formatted_ip_address
    boundary = payment_boundary(conn)
    user = conn.assigns.user
    account_id = user.account_id

    result =
      boundary.create_payment(
        {conn.assigns.client_schema, account_id, ip_address, "web"},
        {amount_in_cents, payment_source_id, agreement_text}
      )

    case result do
      {:ok, rent_saga} ->
        conn
        |> put_status(201)
        |> json(rent_saga)

      {:error, message} when is_binary(message) ->
        conn
        |> put_status(400)
        |> json(%{error: message})

      {:error, %{reason: message}} when is_binary(message) ->
        conn
        |> put_status(400)
        |> json(%{error: message})

      {:error, %AppCount.Core.RentSaga{message: message}} when is_binary(message) ->
        conn
        |> put_status(400)
        |> json(%{error: message})

      unexpected_error ->
        Logger.error(inspect(unexpected_error))

        conn
        |> put_status(400)
        |> json(%{error: "Unknown Error"})
    end
  end
end
