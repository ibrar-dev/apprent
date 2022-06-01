defmodule AppCount.Socials do
  alias AppCount.Socials.Utils.Posts
  alias AppCount.Socials.Utils.Likes
  alias AppCount.Socials.Utils.Blocks
  alias AppCount.Socials.Utils.Reports

  ## ADMIN
  def admin_get_posts(property_id), do: Posts.admin_get_posts(property_id)
  def admin_hide_posts(post_id), do: Posts.admin_hide_posts(post_id)

  ## RESIDENTS
  def create_post(data, params), do: Posts.create_post(data, params)
  def get_posts(tenant_id), do: Posts.get_posts(tenant_id)
  def get_user_posts(tenant_id), do: Posts.get_user_posts(tenant_id)
  def delete_post(post_id), do: Posts.delete_post(post_id)

  def create_like(params), do: Likes.create_like(params)
  def delete_like(params), do: Likes.delete_like(params)
  def get_likes(params), do: Likes.get_likes(params)

  def create_block(params), do: Blocks.create_block(params)
  def create_report(params), do: Reports.create_report(params)
end
