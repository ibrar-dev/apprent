defmodule AppCount.Properties.UnitRepoTest do
  use AppCount.DataCase
  alias AppCount.Tenants.Utils.Queries

  describe "navbar_search/2" do
    setup do
      [builder, property] =
        PropBuilder.new()
        |> PropBuilder.add_property()
        |> PropBuilder.get([:property])

      admin = %AppCountAuth.Users.Admin{property_ids: [property.id], client_schema: "dasmen"}
      ~M[builder, admin]
    end

    test "returns correct unit vacant", ~M[builder, admin] do
      builder
      |> PropBuilder.add_unit(number: "Q3056")
      |> PropBuilder.add_unit(number: "4445")

      [res] = Queries.navbar_search(admin, "Q305")

      assert res.unit == "Q3056"
    end

    test "returns correct unit non vacant", ~M[builder, admin] do
      builder
      |> PropBuilder.add_unit(number: "4445A")
      |> PropBuilder.add_tenant(first_name: "Some", last_name: "Guy")
      |> PropBuilder.add_customer_ledger()
      |> PropBuilder.add_tenancy()
      |> PropBuilder.add_unit(number: "3-56")

      [res] = Queries.navbar_search(admin, "45A")

      assert res.unit == "4445A"
      assert res.name == "Some Guy"
    end
  end
end
