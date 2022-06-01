defmodule AppCount.Tenants.Utils.VehiclesTest do
  use AppCount.DataCase
  import AppCount.LeaseHelper
  alias AppCount.Tenants
  alias AppCount.Tenants.Vehicle
  alias AppCount.Core.ClientSchema
  @moduletag :tenants_utils_vehicles

  setup do
    %{unit: unit, tenants: [tenant]} = insert_lease()
    {:ok, unit: unit, admin: admin_with_access([unit.property_id]), tenant: tenant}
  end

  test "basic CRUD functions", %{admin: admin, tenant: tenant} do
    client = AppCount.Public.get_client_by_schema("dasmen")

    %{
      "make_model" => "Red Fredo",
      "color" => "red",
      "license_plate" => "RDFGD",
      "state" => "NY",
      "tenant_id" => tenant.id
    }
    |> Tenants.create_vehicle()

    vehicle =
      Repo.get_by(Vehicle, [license_plate: "RDFGD", make_model: "Red Fredo"],
        prefix: client.client_schema
      )

    assert vehicle

    Tenants.update_vehicle(
      vehicle.id,
      ClientSchema.new(client.client_schema, %{"color" => "blue"})
    )

    assert Repo.get(Vehicle, vehicle.id, prefix: client.client_schema).color == "blue"
    Tenants.delete_vehicle(ClientSchema.new(client.client_schema, admin), vehicle.id)
    refute Repo.get(Vehicle, vehicle.id, prefix: client.client_schema)
  end
end
