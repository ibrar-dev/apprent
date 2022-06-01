defmodule AppCountWeb.API.TaskController do
  use AppCountWeb, :controller
  alias AppCount.Jobs

  def index(conn, params) do
    json(conn, Jobs.list_tasks(params, conn.assigns.user.client_schema))
  end
end
