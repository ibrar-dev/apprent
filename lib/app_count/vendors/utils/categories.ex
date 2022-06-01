defmodule AppCount.Vendors.Utils.Categories do
  import Ecto.Query
  alias AppCount.Repo
  alias AppCount.Vendors.Category

  def list_categories() do
    from(
      c in Category,
      select: map(c, [:id, :name]),
      order_by: [
        asc: :name
      ]
    )
    |> Repo.all()
  end

  def create_category(params) do
    %Category{}
    |> Category.changeset(params)
    |> Repo.insert()
  end

  def update_category(id, params) do
    Repo.get(Vendor, id)
    |> Category.changeset(params)
    |> Repo.update()
  end

  def delete_category(id) do
    Repo.get(Category, id)
    |> Repo.delete()
  end
end
