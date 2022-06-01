defmodule AppCount.Socials.Utils.Posts do
  import Ecto.Query
  import AppCount.EctoExtensions
  alias AppCount.Repo
  alias AppCount.Socials.Post
  alias AppCount.Socials.Like
  alias AppCount.Socials.Block
  alias AppCount.Socials.Report
  alias AppCount.Accounts.Account

  def create_post(data, params) do
    param2 = Map.merge(data, params["post"])

    %Post{}
    |> Post.changeset(param2)
    |> Repo.insert()
  end

  def get_posts(tenant_id) do
    block_list =
      from(
        b in Block,
        where: b.tenant_id == ^tenant_id,
        select: b.blockee_id
      )
      |> Repo.all()

    property = AppCount.Tenants.property_for(tenant_id)

    account_query =
      from(
        a in Account,
        select: %{
          id: a.id,
          profile_pic: a.profile_pic,
          tenant_id: a.tenant_id,
          username: a.username
        }
      )

    likes_query_count =
      from(
        l in Like,
        select: %{
          id: l.id,
          tenant_id: l.tenant_id,
          post_id: l.post_id
        }
      )

    from(
      p in Post,
      left_join: a in subquery(account_query),
      on: a.tenant_id == p.tenant_id,
      left_join: likes in subquery(likes_query_count),
      on: likes.post_id == p.id,
      where: p.tenant_id not in ^block_list and p.property_id == ^property.id,
      select: %{
        id: p.id,
        text: p.text,
        profile_pic: a.profile_pic,
        username: a.username,
        inserted_at: p.inserted_at,
        property_id: p.property_id,
        tenant_id: p.tenant_id,
        likes: jsonize(likes, [:id, :tenant_id]),
        visible: p.visible
      },
      group_by: [p.id, a.profile_pic, a.username, likes.post_id],
      order_by: [desc: p.inserted_at]
    )
    |> Repo.all()
  end

  def get_user_posts(tenant_id) do
    block_list =
      from(
        b in Block,
        where: b.tenant_id == ^tenant_id,
        select: b.blockee_id
      )
      |> Repo.all()

    property = AppCount.Tenants.property_for(tenant_id)

    account_query =
      from(
        a in Account,
        select: %{
          id: a.id,
          profile_pic: a.profile_pic,
          tenant_id: a.tenant_id,
          username: a.username
        }
      )

    likes_query_count =
      from(
        l in Like,
        select: %{
          id: l.id,
          tenant_id: l.tenant_id,
          post_id: l.post_id
        }
      )

    from(
      p in Post,
      left_join: a in subquery(account_query),
      on: a.tenant_id == p.tenant_id,
      left_join: likes in subquery(likes_query_count),
      on: likes.post_id == p.id,
      where: p.tenant_id not in ^block_list and p.property_id == ^property.id,
      select: %{
        id: p.id,
        text: p.text,
        profile_pic: a.profile_pic,
        username: a.username,
        inserted_at: p.inserted_at,
        property_id: p.property_id,
        tenant_id: p.tenant_id,
        likes: jsonize(likes, [:id, :tenant_id]),
        visible: p.visible
      },
      where: p.tenant_id == ^tenant_id,
      group_by: [p.id, a.profile_pic, a.username, likes.post_id],
      order_by: [desc: p.inserted_at]
    )
    |> Repo.all()
  end

  def admin_hide_posts(post_id) do
    post = Repo.get!(Post, post_id)

    Post.changeset(post, %{visible: false})
    |> Repo.update()
  end

  def admin_get_posts(property_id) do
    likes_query_count =
      from(
        l in Like,
        join: t in assoc(l, :tenant),
        select: %{
          id: l.id,
          tenant_id: l.tenant_id,
          inserted_at: l.inserted_at,
          post_id: l.post_id,
          tenant: fragment("? || ' ' || ?", t.first_name, t.last_name)
        },
        order_by: :inserted_at
      )

    report_query_count =
      from(
        r in Report,
        left_join: t in assoc(r, :tenant),
        left_join: a in assoc(r, :admin),
        select: %{
          id: r.id,
          reason: r.reason,
          inserted_at: r.inserted_at,
          reporter: fragment("? || ' ' || ?", t.first_name, t.last_name),
          admin: a.name,
          post_id: r.post_id
        },
        order_by: :inserted_at
      )

    from(
      p in Post,
      left_join: r in subquery(report_query_count),
      on: r.post_id == p.id,
      left_join: likes in subquery(likes_query_count),
      on: likes.post_id == p.id,
      join: t in assoc(p, :tenant),
      left_join: a in assoc(t, :account),
      where: p.property_id == ^property_id,
      select: %{
        id: p.id,
        text: p.text,
        profile_pic: a.profile_pic,
        username: a.username,
        resident: fragment("? || ' ' || ?", t.first_name, t.last_name),
        inserted_at: p.inserted_at,
        property_id: p.property_id,
        tenant_id: p.tenant_id,
        likes: jsonize(likes, [:id, :tenant_id, :tenant, :inserted_at]),
        reports: jsonize(r, [:id, :reason, :reporter, :admin, :inserted_at]),
        visible: p.visible
      },
      group_by: [p.id, a.profile_pic, a.username, likes.post_id, t.first_name, t.last_name],
      order_by: [desc: p.inserted_at]
    )
    |> Repo.all()
  end

  def delete_post(id) do
    Repo.get(Post, id)
    |> Repo.delete()
  end
end
