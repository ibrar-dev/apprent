defmodule AppCount.Socials.Utils.Likes do
  import Ecto.Query
  alias AppCount.Repo
  alias AppCount.Socials.Like

  def create_like(params) do
    %Like{}
    |> Like.changeset(params)
    |> Repo.insert()
  end

  def get_likes(tenant_id) do
    from(
      l in Like,
      select: %{
        post_id: l.post_id,
        tenant_id: l.tenant_id
      },
      where: l.tenant_id == ^tenant_id,
      group_by: [l.id]
    )
    |> Repo.all()
  end

  def delete_like(params) do
    Repo.get_by!(Like, tenant_id: params.tenant_id, post_id: params.post_id)
    |> Repo.delete()
  end
end
