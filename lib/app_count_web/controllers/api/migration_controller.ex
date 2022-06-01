defmodule AppCountWeb.API.MigrationController do
  use AppCountWeb, :controller
  alias AppCount.Jobs

  def index(conn, _params) do
    json(conn, Jobs.list_migrations())
  end

  def create(conn, %{"migration" => params}) do
    Jobs.create_migration(params)
    json(conn, %{})
  end

  def update(conn, %{"id" => id, "migration" => params}) do
    Jobs.update_migration(id, params)
    json(conn, %{})
  end

  def delete(conn, %{"migration" => id}) do
    Jobs.delete_migration(id)
    json(conn, %{})
  end
end
