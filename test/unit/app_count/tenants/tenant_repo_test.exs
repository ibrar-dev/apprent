defmodule AppCount.Tenants.TenantRepoTest do
  use AppCount.DataCase
  alias AppCount.Tenants.TenantRepo
  alias AppCount.Core.DateTimeRange

  describe "tenant exists" do
    setup do
      [_builder, tenant] =
        PropBuilder.new()
        |> PropBuilder.add_tenant()
        |> PropBuilder.get([:tenant])

      ~M[tenant]
    end

    test "get/1", ~M[tenant] do
      assert TenantRepo.get(tenant.id)
    end

    test "first/0", ~M[tenant] do
      assert TenantRepo.first().id == tenant.id
    end
  end

  describe "tenants_for_unit" do
    test "no tenant" do
      unit = %AppCount.Properties.Unit{}
      date_range = DateTimeRange.today()
      result = TenantRepo.tenants_for_unit(unit, date_range)

      assert result == []
    end

    test "unit has a lease for a tenant" do
      builder =
        PropBuilder.new()
        |> PropBuilder.add_property()
        |> PropBuilder.add_unit()
        |> PropBuilder.add_tenant()
        |> PropBuilder.add_lease()

      unit = PropBuilder.get_requirement(builder, :unit)
      tenant = PropBuilder.get_requirement(builder, :tenant)
      date_range = DateTimeRange.today()

      [tenant_found] = TenantRepo.tenants_for_unit(unit, date_range)

      assert tenant.first_name == tenant_found.first_name
      assert tenant.id == tenant_found.id
    end

    test "unit has a curent lease tenant and a retired lease tenant" do
      builder =
        PropBuilder.new()
        |> PropBuilder.add_property()
        |> PropBuilder.add_unit()
        |> PropBuilder.add_tenant()
        |> PropBuilder.add_lease(
          actual_move_out: Clock.today({-100, :days}),
          start_date: Clock.today({-400, :days}),
          end_date: Clock.today({-100, :days}),
          actual_move_in: Clock.today({-390, :days})
        )
        |> PropBuilder.add_tenant()
        |> PropBuilder.add_lease()

      unit = PropBuilder.get_requirement(builder, :unit)
      tenant = PropBuilder.get_requirement(builder, :tenant)
      date_range = DateTimeRange.today()

      [tenant_found] = TenantRepo.tenants_for_unit(unit, date_range)

      assert tenant.first_name == tenant_found.first_name
      assert tenant.id == tenant_found.id
    end
  end

  describe "tenants_for_property" do
    test "no tenants" do
      builder =
        PropBuilder.new()
        |> PropBuilder.add_property()
        |> PropBuilder.add_unit()

      property = PropBuilder.get_requirement(builder, :property)
      result = TenantRepo.tenants_for_property([property.id])

      assert result == []
    end

    test "has tenants" do
      builder =
        PropBuilder.new()
        |> PropBuilder.add_property()
        |> PropBuilder.add_unit()
        |> PropBuilder.add_tenant()
        |> PropBuilder.add_customer_ledger()
        |> PropBuilder.add_tenancy()

      property = PropBuilder.get_requirement(builder, :property)
      result = TenantRepo.tenants_for_property([property.id])

      assert length(result) == 1
    end
  end

  describe "tenant_by_phone_num/1" do
    test "finds tenant" do
      phone = "1234567890"

      PropBuilder.new()
      |> PropBuilder.add_property()
      |> PropBuilder.add_unit()
      |> PropBuilder.add_tenant(phone: phone)
      |> PropBuilder.add_lease()

      res = TenantRepo.tenant_by_phone_num(phone)

      assert length(res) == 1
    end
  end

  describe "tenant_search/2" do
    setup do
      [builder, property] =
        PropBuilder.new()
        |> PropBuilder.add_property()
        |> PropBuilder.get([:property])

      admin = %AppCountAuth.Users.Admin{property_ids: [property.id], client_schema: "dasmen"}
      ~M[builder, admin]
    end

    test "gets tenant with tenancy", ~M[builder, admin] do
      builder
      |> PropBuilder.add_unit()
      |> PropBuilder.add_tenant(first_name: "Some", last_name: "Guy")
      |> PropBuilder.add_customer_ledger()
      |> PropBuilder.add_tenancy()

      res = TenantRepo.tenant_search(admin, "guy")

      tenant = List.first(res)

      assert length(res) == 1

      assert tenant.name == "Some Guy"
    end

    test "gets tenant with tenancy - email", ~M[builder, admin] do
      builder
      |> PropBuilder.add_unit()
      |> PropBuilder.add_tenant(
        email: "example@example.com",
        first_name: "Some",
        last_name: "Guy"
      )
      |> PropBuilder.add_customer_ledger()
      |> PropBuilder.add_tenancy()

      res = TenantRepo.tenant_search(admin, "example@example.com")

      tenant = List.first(res)

      assert length(res) == 1

      assert tenant.name == "Some Guy"
    end
  end
end
