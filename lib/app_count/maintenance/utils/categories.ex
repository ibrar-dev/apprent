defmodule AppCount.Maintenance.Utils.Categories do
  import Ecto.Query
  alias AppCount.Repo
  alias AppCount.Maintenance.Category
  alias AppCount.Maintenance.Order
  import AppCount.EctoExtensions

  def list_categories({:flat, client_schema}) do
    from(
      c in Category,
      join: p in assoc(c, :parent),
      where: c.visible and p.name not in ["Make Ready", "Third Party"],
      select: map(c, [:id, :name, :parent_id]),
      select_merge: %{
        parent: p.name
      }
    )
    |> Repo.all(prefix: client_schema)
  end

  def list_categories({_type, client_schema}) do
    sub =
      from(
        c in Category,
        left_join: o in assoc(c, :orders),
        where: not is_nil(c.parent_id) and c.visible,
        select: %{
          id: c.id,
          parent_id: c.parent_id,
          name: c.name,
          count: count(o.id),
          visible: c.visible,
          third_party: c.third_party
        },
        group_by: c.id
      )

    from(
      c in Category,
      where: is_nil(c.parent_id) and c.visible,
      left_join: children in subquery(sub),
      on: children.parent_id == c.id,
      select: %{
        id: c.id,
        name: c.name,
        visible: c.visible,
        children: jsonize(children, [:id, :name, :count, :visible, :third_party])
      },
      group_by: c.id,
      order_by: [
        asc: c.name
      ]
    )
    |> Repo.all(prefix: client_schema)
  end

  def list_categories(client_schema) do
    sub =
      from(
        c in Category,
        left_join: o in assoc(c, :orders),
        where: not is_nil(c.parent_id),
        select: %{
          id: c.id,
          parent_id: c.parent_id,
          name: c.name,
          count: count(o.id),
          visible: c.visible,
          third_party: c.third_party
        },
        group_by: c.id
      )

    from(
      c in Category,
      where: is_nil(c.parent_id),
      left_join: children in subquery(sub),
      on: children.parent_id == c.id,
      select: %{
        id: c.id,
        name: c.name,
        visible: c.visible,
        children: jsonize(children, [:id, :name, :count, :visible, :third_party])
      },
      group_by: c.id,
      order_by: [
        asc: c.name
      ]
    )
    |> Repo.all(prefix: client_schema)
  end

  def create_category({attrs, client_schema}) do
    %Category{}
    |> Category.changeset(attrs)
    |> Repo.insert(prefix: client_schema)
  end

  def update_category(id, {params, client_schema}) do
    Repo.get(Category, id)
    |> Category.changeset(params)
    |> Repo.update(prefix: client_schema)
  end

  def transfer(from_id, to_id) do
    from(o in Order, where: o.category_id == ^from_id)
    |> Repo.update_all(
      set: [
        category_id: to_id
      ]
    )
  end

  def delete_category({id, client_schema}) do
    Repo.get(Category, id)
    |> Repo.delete(prefix: client_schema)
  end
end
