defmodule AppCountWeb.API.AssignmentController do
  use AppCountWeb, :controller
  alias AppCount.Repo
  alias AppCount.Core.ClientSchema

  def create(conn, %{"assignment" => params}) do
    order_id = params["order_id"]

    maintenance(conn).assign_order(
      ClientSchema.new(conn.assigns.client_schema, order_id),
      params["tech_id"],
      conn.assigns.admin.id
    )

    json(conn, %{})
  end

  def create(conn, %{"order_ids" => order_ids, "tech_id" => tech_id}) do
    maintenance(conn).assign_orders(
      ClientSchema.new(conn.assigns.client_schema, order_ids),
      tech_id,
      conn.assigns.admin.id
    )

    json(conn, %{})
  end

  def update(conn, %{"id" => assignment_id, "bug" => _}) do
    maintenance(conn).bug_resident_about_rating(conn.assigns.admin, assignment_id)
    json(conn, %{})
  end

  def update(conn, %{"id" => assignment_id, "rating" => rating}) do
    if MapSet.member?(conn.assigns.admin.roles, "Super Admin") or
         MapSet.member?(conn.assigns.admin.roles, "Regional") do
      maintenance(conn).rate_assignment(assignment_id, rating)
    end

    json(conn, %{})
  end

  def update(conn, %{"assignment_id" => assignment_id, "time" => time}) do
    ClientSchema.new(conn.assigns.client_schema, assignment_id)
    |> maintenance(conn).tech_dispatched(time)

    json(conn, %{})
  end

  def update(conn, %{"id" => id, "callback" => _, "note" => note}) do
    assignment = Repo.get(AppCount.Maintenance.Assignment, id)
    result = maintenance(conn).callback_assignment(assignment, conn.assigns.admin, note)

    case result do
      {:ok, _} ->
        json(conn, %{})

      {:error, %{errors: errors}} ->
        message =
          Enum.reduce(errors, "", fn e, acc -> normalize_message(e) <> acc end)
          |> String.slice(0..-2)

        conn
        |> put_status(501)
        |> json(message)
    end
  end

  def update(conn, %{"id" => id, "callback" => _}) do
    assignment = Repo.get(AppCount.Maintenance.Assignment, id, prefix: conn.assigns.client_schema)

    maintenance(conn).callback_assignment(
      ClientSchema.new(conn.assigns.client_schema, assignment)
    )

    json(conn, %{})
  end

  def delete(conn, %{"assignment_ids" => assignment_ids}) do
    conn.assigns.client_schema
    |> ClientSchema.new(assignment_ids)
    |> maintenance(conn).revoke_assignments()

    json(conn, %{})
  end

  def delete(conn, %{"id" => id, "trueDelete" => _}) do
    if MapSet.member?(conn.assigns.admin.roles, "Super Admin") do
      maintenance(conn).delete_assignment(conn.assigns.admin, id)
      json(conn, %{})
    end
  end

  def delete(conn, %{"id" => id}) do
    maintenance(conn).revoke_assignment(ClientSchema.new(conn.assigns.client_schema, id))
    json(conn, %{})
  end

  defp normalize_message({f, {e, _}}) do
    "#{f} #{e},"
    |> String.replace(~r/_id/, "")
    |> String.replace(~r/_/, " ")
    |> String.capitalize()
  end
end
