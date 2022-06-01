defmodule AppCount.Tenants.Utils.Pets do
  alias AppCount.Repo
  alias AppCount.Tenants.Pet
  alias AppCount.Core.ClientSchema

  def create_pet(%AppCount.Core.ClientSchema{name: client_schema, attrs: params}) do
    %Pet{}
    |> Pet.changeset(params)
    |> Repo.insert(prefix: client_schema)
  end

  def update_pet(%AppCount.Core.ClientSchema{name: client_schema, attrs: id}, params) do
    Repo.get(Pet, id, prefix: client_schema)
    |> Pet.changeset(params)
    |> Repo.update(prefix: client_schema)
  end

  def delete_pet(%AppCount.Core.ClientSchema{name: client_schema, attrs: admin}, id) do
    Repo.get(Pet, id, prefix: client_schema)
    |> AppCount.Admins.Utils.Actions.admin_delete(ClientSchema.new(client_schema, admin))
  end
end
