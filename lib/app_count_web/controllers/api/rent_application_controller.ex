defmodule AppCountWeb.API.RentApplicationController do
  use AppCountWeb, :public_controller
  alias AppCount.RentApply
  require Logger

  def create(conn, %{"payment" => payment, "client" => client_schema} = params) do
    RentApply.Process.process(
      client_schema,
      params["property_id"],
      payment,
      params["application_form"],
      conn.assigns.formatted_ip_address
    )
    |> case do
      {:ok, _} ->
        json(conn, %{})

      {:error, %{payment_declined: reason}} ->
        msg =
          "Payment Failure: #{reason}. Please enter different payment information and try again, or save the application and contact the leasing office."

        error_msg(conn, msg)

      {:error, _, _problem} ->
        error_msg(
          conn,
          "Error processing application. Please click 'Cancel' to save the application and then contact the leasing office."
        )

      {:error, _problem} ->
        error_msg(
          conn,
          "Error processing application. Please click 'Cancel' to save the application and then contact the leasing office."
        )
    end
  end

  defp error_msg(conn, msg) do
    conn
    |> put_status(422)
    |> json(%{error: msg})
  end
end
