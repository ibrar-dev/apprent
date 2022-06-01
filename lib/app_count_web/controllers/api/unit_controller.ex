defmodule AppCountWeb.API.UnitController do
  use AppCountWeb, :controller
  alias AppCount.Properties
  alias AppCountWeb.Helpers.ChangesetErrorHandler
  alias AppCount.Core.ClientSchema

  authorize(["Admin", "Agent", "Tech"], delete: ["Super Admin"])

  def index(conn, %{"rentable" => _}) do
    json(
      conn,
      Properties.list_rentable(ClientSchema.new(conn.assigns.client_schema, conn.assigns.admin))
    )
  end

  def index(conn, %{"min" => _} = params) do
    property_ids =
      if !!params["property_ids"] and params["property_ids"] != "" do
        String.split(params["property_ids"], ",")
      else
        nil
      end

    json(
      conn,
      Properties.list_units_min(
        ClientSchema.new(conn.assigns.client_schema, conn.assigns.admin),
        property_ids,
        params["start_date"]
      )
    )
  end

  def index(conn, %{"property_id" => property_id, "start" => start_date}) do
    json(
      conn,
      Properties.get_available_units(
        ClientSchema.new(conn.assigns.client_schema, property_id),
        start_date
      )
    )
  end

  def index(conn, %{"property_id" => property_id}) do
    json(conn, Properties.list_units(conn.assigns.admin, property_id))
  end

  def index(conn, %{"search" => _}) do
    json(conn, Properties.search_units(conn.assigns.admin))
  end

  def index(conn, %{"minSearch" => term}) do
    json(conn, Properties.search_units(conn.assigns.admin, term))
  end

  def index(conn, _) do
    json(
      conn,
      Properties.list_units_min(
        ClientSchema.new(conn.assigns.client_schema, conn.assigns.admin),
        nil,
        nil
      )
    )
  end

  def show(conn, %{"id" => id}) do
    json(conn, Properties.show_unit(conn.assigns.admin, id))
  end

  def create(conn, %{"unit" => params}) do
    Properties.create_unit(ClientSchema.new(conn.assigns.client_schema, params))
    |> handle_error(conn)
  end

  def update(conn, %{"id" => id, "unit" => params}) do
    case properties_boundary(conn).update_unit(id, params) do
      {:ok, unit} ->
        s_json(conn, unit)

      {:error, changeset} ->
        errors = ChangesetErrorHandler.parse_errors(changeset)

        put_status(conn, 422)
        |> json(%{error: errors})
    end
  end

  def delete(conn, %{"id" => id}) do
    Properties.delete_unit(id)
    json(conn, %{success: true})
  end
end
