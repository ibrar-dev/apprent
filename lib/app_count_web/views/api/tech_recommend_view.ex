defmodule AppCountWeb.API.TechRecommendView do
  use AppCountWeb, :view

  def render("index.json", %{techs: techs}) do
    %{data: render_many(techs, __MODULE__, "tech.json")}
  end

  def render("tech.json", %{tech_recommend: %{id: tech_id, name: tech_name}}) do
    %{tech_name: tech_name, tech_id: tech_id}
  end
end
