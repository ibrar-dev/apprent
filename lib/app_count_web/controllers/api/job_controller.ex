defmodule AppCountWeb.API.JobController do
  use AppCountWeb, :controller
  alias AppCount.Jobs

  def index(conn, %{"types" => _}) do
    json(conn, AppCount.Tasks.Workers.list_with_descriptions())
  end

  def index(conn, _params) do
    json(conn, Jobs.list_jobs(conn.assigns.user.client_schema))
  end

  def create(conn, %{"job" => params}) do
    Jobs.create_job(params, conn.assigns.user.client_schema)
    json(conn, %{})
  end

  def update(conn, %{"id" => id, "job" => params}) do
    Jobs.update_job(id, params, conn.assigns.user.client_schema)
    json(conn, %{})
  end

  def delete(conn, %{"id" => id}) do
    Jobs.delete_job(id, conn.assigns.user.client_schema)
    json(conn, %{})
  end
end
