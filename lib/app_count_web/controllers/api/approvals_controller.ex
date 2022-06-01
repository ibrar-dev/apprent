defmodule AppCountWeb.API.ApprovalsController do
  use AppCountWeb, :controller

  alias AppCount.Approvals
  require Logger

  def index(conn, %{"approvers" => _}) do
    json(conn, Approvals.list_approvers(conn.assigns.user))
  end

  def index(conn, %{"nextNum" => _, "payee_id" => payee_id, "property_id" => property_id}) do
    json(conn, Approvals.get_next_num(payee_id, property_id))
  end

  def index(conn, %{"categories" => property_id}) do
    json(conn, Approvals.list_categories_for_approval(property_id))
  end

  def index(conn, %{"adminData" => _, "approval_id" => admin_id, "property_id" => property_id}) do
    json(conn, Approvals.list_admin_data(admin_id, property_id))
  end

  def index(conn, %{"adminData" => _, "property_id" => property_id}) do
    json(conn, Approvals.list_admin_data(conn.assigns.user.id, property_id))
  end

  # This is the main one that the index calls.
  # Maybe only pass in admin and backend filters?
  def index(conn, %{"property_ids" => property_ids}) do
    json(
      conn,
      Approvals.list_approvals(conn.assigns.user.property_ids, property_ids)
    )
  end

  def show(conn, %{"id" => id}) do
    json(conn, Approvals.show_approval(id, conn.assigns.client_schema))
  end

  def create(conn, %{"approval" => params}) do
    new_params = Map.merge(params, %{"admin_id" => conn.assigns.admin.id})

    case Approvals.create_approval(new_params, conn.assigns.user.client_schema) do
      {:ok, _} ->
        json(conn, %{})

      {:error, _, %{errors: errors}, _} ->
        message =
          Enum.reduce(errors, "", fn e, acc -> normalize_message(e) <> acc end)
          |> String.slice(0..-2)

        conn
        |> put_status(501)
        |> json(message)

      e ->
        Logger.error(e)
    end
  end

  def create(conn, %{"approval_note" => params}) do
    new_params = Map.merge(params, %{"admin_id" => conn.assigns.admin.id})

    case Approvals.create_approval_note(new_params) do
      {:ok, _} ->
        json(conn, %{})

      {:error, %{errors: errors}} ->
        message =
          Enum.reduce(errors, "", fn e, acc -> normalize_message(e) <> acc end)
          |> String.slice(0..-2)

        conn
        |> put_status(501)
        |> json(message)

      {:error, _, %{errors: errors}, _} ->
        message =
          Enum.reduce(errors, "", fn e, acc -> normalize_message(e) <> acc end)
          |> String.slice(0..-2)

        conn
        |> put_status(501)
        |> json(message)
    end
  end

  def update(conn, %{"id" => id, "approval" => params}) do
    case Approvals.update_approval(id, params, conn.assigns.user.client_schema) do
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

  def delete(conn, %{"deleteAttachment" => _, "id" => id}) do
    Approvals.delete_attachment(id)
    json(conn, %{})
  end

  defp normalize_message({f, {e, _}}) do
    "#{f} #{e},"
    |> String.replace(~r/_id/, "")
    |> String.replace(~r/_/, " ")
    |> String.capitalize()
  end
end
