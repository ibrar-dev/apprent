defmodule AppCountWeb.API.InsightReportSubscriptionsController do
  use AppCountWeb, :controller

  alias AppCount.Maintenance.InsightReportSubscriptions

  authorize([], show: ["Admin"])

  def index(conn, %{"admin_id" => admin_id}) do
    list =
      admin_id
      |> InsightReportSubscriptions.index()
      |> Enum.map(fn i ->
        %{id: i.id, property_id: i.property_id, admin_id: i.admin_id, type: i.type}
      end)

    json(conn, %{list: list})
  end

  def delete(conn, %{"id" => id}) do
    InsightReportSubscriptions.destroy(id)

    json(conn, %{status: "ok"})
  end

  # Params:
  # - property_id
  # - admin_id
  # - type
  def create(conn, params) do
    new_params = %{
      property_id: params["property_id"],
      admin_id: params["admin_id"],
      type: params["type"]
    }

    case InsightReportSubscriptions.create(new_params) do
      {:ok, _} ->
        list =
          new_params.admin_id
          |> InsightReportSubscriptions.index()
          |> Enum.map(fn i ->
            %{id: i.id, property_id: i.property_id, admin_id: i.admin_id, type: i.type}
          end)

        data = %{
          list: list
        }

        conn
        |> put_status(201)
        |> json(data)

      err ->
        conn
        |> put_status(400)
        |> json(%{error: err})
    end
  end
end
