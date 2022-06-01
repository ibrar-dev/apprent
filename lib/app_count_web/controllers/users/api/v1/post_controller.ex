defmodule AppCountWeb.Users.API.V1.PostController do
  use AppCountWeb.Users, :controller
  alias AppCount.Socials

  def index(conn, _params) do
    posts = Socials.get_posts(conn.assigns.user.id)
    likes = Socials.get_likes(conn.assigns.user.id)
    json(conn, %{posts: posts, likes: likes})
  end

  def create(conn, params) do
    Socials.create_post(
      %{"tenant_id" => conn.assigns.user.id, "property_id" => conn.assigns.user.property.id},
      params
    )

    json(conn, %{})
    #        |> redirect(to: Routes.user_social_path(conn, :index))
  end

  def update(conn, %{"blockee" => params}) do
    Socials.create_block(params)
    json(conn, %{})
  end

  def update(conn, %{"report" => params}) do
    Socials.create_report(params)
    json(conn, %{})
  end

  def update(conn, %{"id" => id, "params" => params}) do
    if params["like_id"] == "" do
      Socials.create_like(
        Map.merge(params, %{
          "tenant_id" => conn.assigns.user.id,
          "post_id" => String.to_integer(id)
        })
      )
    else
      Socials.delete_like(%{post_id: String.to_integer(id), tenant_id: conn.assigns.user.id})
    end

    json(conn, %{})
  end

  def delete(conn, %{"id" => id}) do
    Socials.delete_post(id)
    json(conn, %{})
  end
end
