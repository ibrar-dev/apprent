defmodule AppCountWeb.API.RecurringLetterController do
  use AppCountWeb, :controller
  alias AppCount.Properties.Utils.RecurringLetters

  authorize(["Regional", "Super Admin"], index: ["Agent", "Admin"])

  def index(conn, %{"property_id" => property_id}) do
    json(conn, RecurringLetters.list_recurring_letters(conn.assigns.admin, property_id))
  end

  def create(conn, %{"recurring_letter" => params}) do
    case RecurringLetters.create_recurring_letter(params) do
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

  def show(conn, %{"id" => id, "preview" => _}) do
    json(conn, AppCount.Properties.Utils.ResidentParams.get_residents_with_params(id))
  end

  def show(conn, %{"id" => id}) do
    RecurringLetters.run_recurring_letters_early(id)
    json(conn, %{})
  end

  def update(conn, %{"id" => id, "recurring_letter" => params}) do
    case RecurringLetters.update_recurring_letter(id, params) do
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
    RecurringLetters.delete_recurring_letter(id)
    json(conn, %{})
  end

  defp normalize_message({f, {e, _}}) do
    "#{f} #{e},"
    |> String.replace(~r/_id/, "")
    |> String.replace(~r/_/, " ")
    |> String.capitalize()
  end
end
