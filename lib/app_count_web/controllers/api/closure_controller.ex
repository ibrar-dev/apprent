defmodule AppCountWeb.API.ClosureController do
  use AppCountWeb, :controller
  alias AppCount.Prospects
  authorize(["Regional", "Admin"], index: ["Admin", "Agent"])

  def index(conn, %{"property_id" => property_id}) do
    json(conn, Prospects.list_closures(property_id))
  end

  def create(conn, %{"closure" => params, "all" => _}) do
    if MapSet.member?(conn.assigns.admin.roles, "Super Admin") do
      new_params = Map.merge(params, %{"admin" => conn.assigns.admin.name})
      Prospects.create_closure(new_params, :all)
      json(conn, %{})
    else
      conn
      |> put_status(401)
      |> json("Unauthorized to set company wide closings")
    end
  end

  def create(conn, %{"closure" => params}) do
    new_params = Map.merge(params, %{"admin" => conn.assigns.admin.name})

    case Prospects.create_closure(new_params) do
      {:ok, _} ->
        json(conn, %{})

      {:error, %{errors: errors}} ->
        message =
          Enum.reduce(errors, "", fn e, acc -> normalize_message(e) <> acc end)
          |> String.slice(0..-2)

        conn
        |> put_status(401)
        |> json(message)
    end
  end

  def update(conn, %{"id" => id, "closure" => params}) do
    case Prospects.update_closure(id, params) do
      {:ok, _} ->
        json(conn, %{})

      {:error, %{errors: errors}} ->
        message =
          Enum.reduce(errors, "", fn e, acc -> normalize_message(e) <> acc end)
          |> String.slice(0..-2)

        conn
        |> put_status(401)
        |> json(message)
    end
  end

  def show(conn, %{"id" => property_id, "date" => date}) do
    json(conn, Prospects.list_affected_showings(property_id, date))
  end

  def delete(conn, %{"id" => id}) do
    Prospects.delete_closures(id)
    json(conn, %{})
  end

  defp normalize_message({f, {e, _}}) do
    "#{f} #{e},"
    |> String.replace(~r/_id/, "")
    |> String.replace(~r/_/, " ")
    |> String.capitalize()
  end
end
