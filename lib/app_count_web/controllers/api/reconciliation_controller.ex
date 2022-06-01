defmodule AppCountWeb.API.ReconciliationController do
  use AppCountWeb, :controller
  alias AppCount.Accounting

  def delete_posting do
  end

  def create(conn, %{"params" => params}) do
    case Accounting.create_reconciliation(params) do
      {:ok, _} ->
        json(conn, %{})

      {:error, %{errors: _}} ->
        conn
        |> put_status(501)
        |> json({})
    end
  end
end
