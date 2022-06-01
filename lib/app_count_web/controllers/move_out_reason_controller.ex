defmodule AppCountWeb.API.MoveOutReasonController do
  use AppCountWeb, :controller
  alias AppCount.Settings

  authorize(["Super Admin"], index: ["Super Admin", "Regional", "Admin", "Agent"])

  def index(conn, _params) do
    json(conn, Settings.list_move_out_reasons())
  end

  def create(conn, %{"move_out_reason" => params}) do
    Settings.create_move_out_reason(params)
    json(conn, %{})
  end

  #
  #  def update(conn, %{"id" => id, "move_out_reason" => params}) do
  #    Settings.update_move_out_reason(id, params)
  #    json(conn, %{})
  #  end

  def delete(conn, %{"id" => id}) do
    Settings.delete_move_out_reason(id)
    |> handle_error(conn)
  end
end
