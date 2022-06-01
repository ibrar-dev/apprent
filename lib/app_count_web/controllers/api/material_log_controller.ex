defmodule AppCountWeb.API.MaterialLogController do
  use AppCountWeb, :controller
  alias AppCount.Materials
  require Logger

  def index(conn, %{"stock" => id, "startDate" => start_date, "endDate" => end_date}) do
    {:ok, timex_start_date} = Timex.parse(start_date, "{ISOdate}")
    {:ok, timex_end_date} = Timex.parse(end_date, "{ISOdate}")
    json(conn, Materials.list_material_logs(id, timex_start_date, timex_end_date))
  end

  def create(conn, %{"log" => params, "material" => material}) do
    params
    |> Map.put("admin", conn.assigns.admin.name)
    |> Materials.send_materials(material)

    json(conn, %{})
  end

  def update(conn, %{"id" => id, "material_log" => params, "return" => _}) do
    info = %{date: AppCount.current_time(), admin: conn.assigns.admin.name}
    new_params = params |> Map.merge(%{"returned" => info})
    Materials.update_material_log(id, new_params)
    json(conn, %{})
  end

  def update(conn, %{"id" => id, "material_log" => params}) do
    Materials.update_material_log(id, params)
    json(conn, %{})
  end
end
