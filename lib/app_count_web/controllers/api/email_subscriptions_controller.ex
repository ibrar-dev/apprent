defmodule AppCountWeb.API.EmailSubscriptionsController do
  use AppCountWeb, :controller
  alias AppCount.Admins
  alias AppCount.Core.ClientSchema

  def show(conn, %{"id" => admin_id}) do
    json(conn, Admins.get_subscriptions(ClientSchema.new(conn.assigns.client_schema, admin_id)))
  end

  def update(conn, %{"subscribe" => trigger, "id" => admin_id}) do
    case Admins.subscribe(ClientSchema.new(conn.assigns.client_schema, admin_id), trigger) do
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

  def update(conn, %{"unsubscribe" => trigger, "id" => admin_id}) do
    case Admins.unsubscribe(ClientSchema.new(conn.assigns.client_schema, admin_id), trigger) do
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
