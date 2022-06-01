defmodule AppCountWeb.API.PostController do
  use AppCountWeb, :controller
  alias AppCount.Socials

  def index(conn, %{"property_id" => property_id}) do
    json(conn, Socials.admin_get_posts(property_id))
  end

  def update(conn, %{"id" => id, "deletePost" => _}) do
    Socials.admin_hide_posts(id)
    json(conn, %{})
  end
end
