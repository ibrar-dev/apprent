defmodule AppCountWeb.API.ApprovalsLogsController do
  use AppCountWeb, :controller
  alias AppCount.Approvals
  alias AppCount.Core.ClientSchema

  def update(conn, %{"id" => id, "approval_log" => params}) do
    new_params =
      cond do
        is_nil(params["admin_id"]) ->
          Map.merge(params, %{"approval_id" => id, "admin_id" => conn.assigns.admin.id})

        true ->
          Map.merge(params, %{"approval_id" => id, "bugger_id" => conn.assigns.admin.id})
      end

    case Approvals.create_approval_log(ClientSchema.new(conn.assigns.client_schema, new_params)) do
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

  def delete(conn, %{"id" => id}) do
    case Approvals.delete_approval_log(id, conn.assigns.user.client_schema) do
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

  defp normalize_message({f, {e, _}}) do
    "#{f} #{e},"
    |> String.replace(~r/_id/, "")
    |> String.replace(~r/_/, " ")
    |> String.capitalize()
  end
end
