defmodule AppCount.Tenants.Utils.PetsTest do
  use AppCount.DataCase
  import AppCount.LeaseHelper
  alias AppCount.Tenants
  alias AppCount.Tenants.Pet
  alias AppCount.Core.ClientSchema
  @moduletag :tenants_utils_pets

  setup do
    %{unit: unit, tenants: [tenant]} = insert_lease()
    {:ok, unit: unit, admin: admin_with_access([unit.property_id]), tenant: tenant}
  end

  test "basic CRUD functions", %{admin: admin, tenant: tenant} do
    client = AppCount.Public.ClientRepo.from_schema("dasmen")

    ClientSchema.new(
      client.client_schema,
      %{
        "type" => "dog",
        "breed" => "husky",
        "weight" => "12lb",
        "name" => "Sparky",
        "tenant_id" => tenant.id
      }
    )
    |> Tenants.create_pet()

    pet = Repo.get_by(Pet, [name: "Sparky", type: "dog"], prefix: client.client_schema)
    assert pet
    Tenants.update_pet(ClientSchema.new(client.client_schema, pet.id), %{"name" => "Fido"})
    assert Repo.get(Pet, pet.id, prefix: client.client_schema).name == "Fido"
    Tenants.delete_pet(ClientSchema.new(client.client_schema, admin), pet.id)
    refute Repo.get(Pet, pet.id, prefix: client.client_schema)
  end
end
