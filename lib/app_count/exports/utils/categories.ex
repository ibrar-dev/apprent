defmodule AppCount.Exports.Utils.Categories do
  alias AppCount.Repo
  alias AppCount.Exports.Category
  import Ecto.Query
  import AppCount.EctoExtensions

  def list_categories(admin_id) do
    from(
      c in Category,
      left_join: d in assoc(c, :documents),
      left_join: doc in assoc(d, :document_url),
      where: c.admin_id == ^admin_id,
      select: %{
        id: c.id,
        name: c.name,
        documents:
          type(
            jsonize(d, [:id, :name, :type, {:date, d.inserted_at}, {:url, doc.url}]),
            AppCount.Data.Uploads
          )
      },
      group_by: c.id
    )
    |> Repo.all()
  end

  def insert_category(params) do
    %Category{}
    |> Category.changeset(params)
    |> Repo.insert()
  end

  def update_category(id, params) do
    Repo.get(Category, id)
    |> Category.changeset(params)
    |> Repo.update()
  end

  def delete_category(id) do
    Repo.get(Category, id)
    |> Repo.delete()
  end
end
