defmodule AppCount.Materials.Utils.Types do
  alias AppCount.Repo
  alias AppCount.Materials.Type

  def list_material_types do
    Repo.all(Type)
  end

  def create_material_type(params) do
    %Type{}
    |> Type.changeset(params)
    |> Repo.insert()
  end

  def update_material_type(id, params) do
    Repo.get(Type, id)
    |> Type.changeset(params)
    |> Repo.update()
  end

  def delete_material_type(id) do
    Repo.get(Type, id)
    |> Repo.delete()
  end
end
