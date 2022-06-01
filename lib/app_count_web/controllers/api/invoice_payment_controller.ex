defmodule AppCountWeb.API.InvoicePaymentController do
  use AppCountWeb, :controller
  alias AppCount.Accounting

  def create(conn, %{"payment" => params}) do
    Accounting.create_invoice_payment(params)
    |> handle_error(conn)
  end

  def create(conn, %{"payments" => params}) do
    Accounting.create_invoice_payments(params)
    |> handle_error(conn)
  end

  def create(conn, %{"batch_payments" => params}) do
    render_fn = &AppCountWeb.LetterPreviewer.render_check_template/1

    case Accounting.create_batch_payments(params, render_fn) do
      {:error, _} = e -> handle_error(e, conn)
      checks -> json(conn, %{checks: checks})
    end
  end

  def delete(conn, %{"id" => id}) do
    Accounting.delete_invoice_payment(id)
    json(conn, %{})
  end
end
