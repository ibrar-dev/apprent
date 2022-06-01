defmodule AppCountWeb.Users.API.V2.PaymentController do
  use AppCountWeb.Users, :controller
  require Logger

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

    case boundary.create_payment(
           {conn.assigns.client_schema, account_id, ip_address, "mobile"},
           {amount_in_cents, payment_source_id, agreement_text}
         ) do
      {:ok, rent_saga} ->
        conn
        |> put_status(201)
        |> json(rent_saga)

      {:error, %AppCount.Core.RentSaga{message: message}} when is_binary(message) ->
        conn
        |> put_status(400)
        |> json(%{error: message})

      {:error, message} when is_binary(message) ->
        conn
        |> put_status(400)
        |> json(%{error: message})

      unexpected_error ->
        Logger.error(inspect(unexpected_error))

        conn
        |> put_status(400)
        |> json(%{error: "Unknown"})
    end
  end
end
