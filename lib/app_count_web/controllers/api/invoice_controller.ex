defmodule AppCountWeb.API.InvoiceController do
  use AppCountWeb, :controller
  alias AppCount.Accounting

  authorize(["Accountant"])

  def index(conn, params) do
    json(conn, Accounting.list_invoices(conn.assigns.admin, params))
  end

  def create(conn, %{"invoice" => params}) do
    case Accounting.create_invoice(params) do
      {:ok, _} ->
        json(conn, %{})

      {:error, _, %{errors: errors}, _} ->
        message =
          Enum.reduce(errors, "", fn e, acc -> normalize_message(e) <> acc end)
          |> String.slice(0..-2)

        conn
        |> put_status(501)
        |> json(message)
    end
  end

  def update(conn, %{"id" => id, "invoice" => params}) do
    Accounting.update_invoice(id, params)
    json(conn, %{})
  end

  def delete(conn, %{"id" => id}) do
    Accounting.delete_invoice(id)
    json(conn, %{})
  end

  defp normalize_message({f, {e, _}}) do
    "#{f} #{e},"
    |> String.replace(~r/_id/, "")
    |> String.replace(~r/_/, " ")
    |> String.capitalize()
  end
end
