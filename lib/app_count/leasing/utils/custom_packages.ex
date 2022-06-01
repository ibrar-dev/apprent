defmodule AppCount.Leasing.Utils.CustomPackages do
  alias AppCount.Repo
  alias AppCount.Leasing.CustomPackage
  alias AppCount.Core.ClientSchema

  def create_custom_package(%ClientSchema{
        name: client_schema,
        attrs: params
      }) do
    %CustomPackage{}
    |> CustomPackage.changeset(params)
    |> Repo.insert(prefix: client_schema)
  end

  def update_custom_package(
        %ClientSchema{
          name: client_schema,
          attrs: id
        },
        params
      ) do
    Repo.get(CustomPackage, id, prefix: client_schema)
    |> CustomPackage.changeset(params)
    |> Repo.update(prefix: client_schema)
  end

  def delete_custom_package(%ClientSchema{
        name: client_schema,
        attrs: id
      }) do
    Repo.get(CustomPackage, id, prefix: client_schema)
    |> Repo.delete(prefix: client_schema)
  end

  def add_note(
        %ClientSchema{
          name: client_schema,
          attrs: id
        },
        text,
        admin
      ) do
    pack = Repo.get(CustomPackage, id, prefix: client_schema)

    notes =
      pack.notes ++ [%{"text" => text, "admin" => admin.name, "time" => AppCount.current_time()}]

    pack
    |> CustomPackage.changeset(%{notes: notes})
    |> Repo.update(prefix: client_schema)
  end
end
