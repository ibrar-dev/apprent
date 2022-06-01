defmodule AppCountWeb.API.ApplicationLeaseController do
  use AppCountWeb, :controller
  alias AppCount.Leases
  alias AppCount.RentApply
  authorize(["Admin", "Agent"])

  def show(conn, %{"id" => id}) do
    json(conn, Leases.get_application_lease_form(id))
  end

  def update(conn, %{"id" => id, "unlock" => _}) do
    if AppCount.Admins.has_role?("Super Admin", conn.assigns.admin.roles) do
      Leases.unlock_form(id)
      json(conn, %{})
    else
      conn
      |> put_status(:unauthorized)
      |> json(%{error: "Unauthorized"})
    end
  end

  def update(conn, %{"id" => id, "lease" => params}) do
    case Leases.update_form(id, params) do
      {:ok, _} ->
        json(conn, %{})

      {:ok, _, _} ->
        json(conn, %{})

      {:error, :locked} ->
        conn
        |> put_status(422)
        |> json(%{error: "Lease has already been locked"})

      {:error, _} ->
        conn
        |> put_status(422)
        |> json(%{error: "Something went wrong"})
    end
  end

  def update(conn, %{"id" => id}) do
    try do
      case RentApply.create_bluemoon_lease_from_application(conn.assigns.admin, id) do
        {:ok, _} ->
          RentApply.update_application(id, %{status: "lease_sent"})
          json(conn, %{})

        {:error, message} ->
          conn
          |> put_status(422)
          |> json(%{error: message})
      end
    rescue
      e in RuntimeError ->
        conn
        |> put_status(422)
        |> json(%{error: e.message})
    end
  end
end
