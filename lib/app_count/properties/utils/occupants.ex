defmodule AppCount.Properties.Utils.Occupants do
  alias AppCount.Repo
  alias AppCount.Properties.Occupant
  alias AppCount.Core.ClientSchema

  def create_occupant(%AppCount.Core.ClientSchema{name: client_schema, attrs: params}) do
    %Occupant{}
    |> Occupant.changeset(params)
    |> Repo.insert(prefix: client_schema)
  end

  def update_occupant(id, %AppCount.Core.ClientSchema{name: client_schema, attrs: params}) do
    Repo.get(Occupant, id)
    |> Occupant.changeset(params)
    |> Repo.update(prefix: client_schema)
  end

  def delete_occupant(%AppCount.Core.ClientSchema{name: client_schema, attrs: admin}, id) do
    Repo.get(Occupant, id, prefix: client_schema)
    |> AppCount.Admins.Utils.Actions.admin_delete(ClientSchema.new(client_schema, admin))
  end
end
