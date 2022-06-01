defmodule AppCount.Accounts.PackagesTest do
  use AppCount.DataCase
  alias AppCount.Properties
  alias AppCount.PackageHelper
  @moduletag :packages

  setup do
    property = insert(:property)
    unit = insert(:unit, property: property)
    lease = insert(:lease, unit: unit)
    tenant = List.first(lease.tenants)
    package = insert(:package, tenant: tenant, unit: unit)
    {:ok, %{unit: unit, tenant: tenant, package: package, property: property}}
  end

  test "create_package function works", %{unit: unit, tenant: tenant} do
    params = %{
      "name" => "Test Package1",
      "condition" => "Good",
      "status" => "Delivered",
      "carrier" => "USPS",
      "notes" => "test test1",
      "admin" => "Tester1",
      "reason" => "Show ID",
      "tenant_id" => tenant.id,
      "unit_id" => unit.id
    }

    {:ok, package} = Properties.create_package(params)
    assert package.name == "Test Package1"
    assert package.tenant_id == tenant.id
    assert package.unit_id == unit.id
  end

  test "list_packages function works", %{property: property} do
    before_length = Properties.list_packages(%{property_ids: [property.id]}) |> length
    PackageHelper.insert_package(property, 5)
    after_length = Properties.list_packages(%{property_ids: [property.id]}) |> length
    assert before_length + 5 == after_length
  end

  test "update_package function works", %{package: package} do
    params = %{name: "Updated Work", condition: "Very Good"}
    {:ok, new_package} = Properties.update_package(package.id, params)
    assert new_package.name == "Updated Work"
    assert new_package.condition == "Very Good"
  end

  test "delete_package function works", %{package: package} do
    Properties.delete_package(package.id)
    new_package = Repo.get(Properties.Package, package.id)
    assert new_package == nil
  end

  test "list_resident_packages function works", %{unit: unit, tenant: tenant} do
    before_length = Properties.list_resident_packages(tenant.id) |> length
    PackageHelper.insert_resident_package(tenant, unit, 5)
    after_length = Properties.list_resident_packages(tenant.id) |> length
    assert before_length + 5 == after_length
  end
end
