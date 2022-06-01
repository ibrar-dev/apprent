defmodule AppCountWeb.API.RegionController do
  use AppCountWeb, :controller
  alias AppCount.Properties
  require Logger

  authorize(["Super Admin"], index: ["Accountant", "Agent", "Admin", "Tech", "Regional"])

  def index(conn, _) do
    json(conn, Properties.list_regions())
  end

  def create(conn, %{"region" => params}) do
    case Properties.create_region(params) do
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

  def update(conn, %{"id" => id, "region" => params}) do
    case Properties.update_region(id, params) do
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

  defp normalize_message({f, {e, _}}) do
    "#{f} #{e},"
    |> String.replace(~r/_id/, "")
    |> String.replace(~r/_/, " ")
    |> String.capitalize()
  end
end
