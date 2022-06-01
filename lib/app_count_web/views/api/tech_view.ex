defmodule AppCountWeb.API.TechView do
  use AppCountWeb, :view

  def render("index.json", %{techs: techs}) do
    render_many(techs, __MODULE__, "tech.json")
  end

  def render("show.json", %{tech: tech}) do
    %{
      completion_time: tech.completion_time,
      rating: tech.rating
    }
  end

  def render("tech.json", %{tech: tech}) do
    tech
  end
end
