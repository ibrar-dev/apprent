defmodule AppCountWeb.API.TechRecommendController do
  use AppCountWeb, :controller

  def index(conn, %{"work_order_id" => work_order_id} = _params) do
    work_order_id = work_order_id |> String.to_integer()
    techs = tech_recommend_boundary(conn).recommend(work_order_id)
    render(conn, "index.json", techs: techs)
  end
end
