defmodule AppCount.PackageHelper do
  import AppCount.Factory

  def insert_package(property, amount) do
    amount = amount - 1

    Enum.each(
      0..amount,
      fn x ->
        unit = insert(:unit, property: property)
        lease = insert(:lease, unit: unit)
        tenant = List.first(lease.tenants)
        insert(:package, tenant: tenant, unit: unit, name: "Test#{x}")
      end
    )
  end

  def insert_resident_package(tenant, unit, amount) do
    amount = amount - 1

    Enum.each(
      0..amount,
      fn _ ->
        insert(:package, tenant: tenant, unit: unit)
      end
    )
  end
end
