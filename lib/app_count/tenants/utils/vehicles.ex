defmodule AppCount.Tenants.Utils.Vehicles do
  alias AppCount.Repo
  alias AppCount.Tenants.Vehicle
  alias AppCount.Core.ClientSchema

  def create_vehicle(params) do
    %Vehicle{}
    |> Vehicle.changeset(params)
    |> Repo.insert()
  end

  def update_vehicle(id, %AppCount.Core.ClientSchema{name: client_schema, attrs: params}) do
    Repo.get(Vehicle, id)
    |> Vehicle.changeset(params)
    |> Repo.update(prefix: client_schema)
  end

  def delete_vehicle(%AppCount.Core.ClientSchema{name: client_schema, attrs: admin}, id) do
    Repo.get(Vehicle, id, prefix: client_schema)
    |> AppCount.Admins.Utils.Actions.admin_delete(ClientSchema.new(client_schema, admin))
  end
end
