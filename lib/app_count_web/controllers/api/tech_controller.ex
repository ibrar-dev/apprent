defmodule AppCountWeb.API.TechController do
  alias AppCountWeb.Helpers.ChangesetErrorHandler
  alias AppCount.Core.ClientSchema
  use AppCountWeb, :controller

  authorize(["Tech", "Accountant", "Admin"])

  def index(conn, %{"min" => _}) do
    json(
      conn,
      maintenance(conn).list_techs(
        ClientSchema.new(conn.assigns.client_schema, conn.assigns.user),
        :min
      )
    )
  end

  def index(conn, %{"tech" => _}) do
    techs =
      maintenance(conn).list_techs(
        ClientSchema.new(conn.assigns.client_schema, conn.assigns.user),
        :tech
      )

    render(conn, "index.json", techs: techs)
  end

  def index(conn, %{"loc" => _}) do
    techs =
      maintenance(conn).list_techs(
        ClientSchema.new(conn.assigns.client_schema, conn.assigns.user),
        :loc
      )

    render(conn, "index.json", techs: techs)
  end

  def index(conn, %{"assign" => _}) do
    techs =
      maintenance(conn).list_techs(
        ClientSchema.new(conn.assigns.client_schema, conn.assigns.user),
        :assign
      )

    render(conn, "index.json", techs: techs)
  end

  def index(conn, _params) do
    techs =
      maintenance(conn).list_techs(
        ClientSchema.new(conn.assigns.client_schema, conn.assigns.user)
      )

    render(conn, "index.json", techs: techs)
  end

  def show(conn, %{"id" => id, "detailed_info" => _}) do
    tech = maintenance(conn).tech_detailed_info(ClientSchema.new(conn.assigns.client_schema, id))
    render(conn, "tech.json", tech: tech)
  end

  def show(conn, %{"id" => id, "pastStats" => _}) do
    stats = maintenance(conn).last_six_months(ClientSchema.new(conn.assigns.client_schema, id))
    render(conn, "tech.json", tech: stats)
  end

  def show(conn, %{"id" => id}) do
    tech = maintenance(conn).tech_details(ClientSchema.new(conn.assigns.client_schema, id))
    render(conn, "show.json", tech: tech)
  end

  def create(conn, %{"tech" => params}) do
    case maintenance(conn).create_tech(params) do
      {:ok, _} ->
        json(conn, %{})

      {:error, changeset} ->
        errors = ChangesetErrorHandler.parse_errors(changeset)

        put_status(conn, 400)
        |> json(%{errors: errors})
    end
  end

  def update(conn, %{"id" => id, "all_categories" => _}) do
    conn.assigns.client_schema
    |> ClientSchema.new(id)
    |> maintenance(conn).set_all_categories()

    json(conn, %{})
  end

  def update(conn, %{"id" => id, "pass_code" => _}) do
    maintenance(conn).set_pass_code(id)
    json(conn, %{})
  end

  def update(conn, %{"id" => id, "tech" => params}) do
    conn.assigns.client_schema
    |> ClientSchema.new(id)
    |> maintenance(conn).update_tech(Map.delete(params, "pass_code"))

    json(conn, %{})
  end

  def delete(conn, %{"id" => id}) do
    maintenance(conn).delete_tech(id)
    json(conn, %{})
  end
end
