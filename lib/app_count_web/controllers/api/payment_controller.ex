defmodule AppCountWeb.API.PaymentController do
  use AppCountWeb, :controller
  alias AppCount.Ledgers.Utils.Payments
  alias AppCount.Ledgers.Utils.PaymentNSFs
  alias AppCount.Ledgers.PaymentRepo

  authorize(["Accountant", "Admin", "Agent"], update: ["Accountant"])

  def index(conn, params) do
    json(conn, Payments.list_payments(conn.assigns.admin, params))
  end

  def create(conn, %{"nsf" => params}) do
    params
    |> Map.merge(%{"admin" => conn.assigns.admin.name})
    |> PaymentNSFs.create_nsf()
    |> case do
      {:ok, _} -> json(conn, %{status: :ok})
      _ -> json(conn, %{status: :error})
    end
  end

  def show(conn, %{"id" => id, "type" => "nsf_proof"}) do
    %{url: url, content_type: content_type} = PaymentNSFs.get_nsf_proof(id)
    json(conn, %{url: url, content_type: content_type})
  end

  def show(conn, %{"id" => id, "type" => _}) do
    url = Payments.get_payment_image(id)

    content_type =
      url
      |> URI.parse()
      |> Map.get(:path)
      |> MIME.from_path()

    json(conn, %{url: url, content_type: content_type})
  end

  def show(conn, %{"id" => id}) do
    json(conn, PaymentRepo.show_payment(String.to_integer(id)))
  end

  def update(conn, %{"id" => id, "payment" => params}) do
    Payments.update_payment(conn.assigns.admin, id, params)
    json(conn, %{})
  end

  def delete(conn, %{"id" => id}) do
    Payments.delete_payment(conn.assigns.admin, id)
    json(conn, %{})
  end
end
