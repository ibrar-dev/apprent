defmodule AppCount.Admins.AdminRepoTest do
  use AppCount.DataCase
  alias AppCount.Admins.Admin
  alias AppCount.Admins.AdminRepo
  alias AppCount.Properties.PropertyRepo
  alias AppCount.Core.ClientSchema

  def default_setting(extra \\ %{}) do
    # AppCount.Properties.Setting
    %{
      admin_fee: 10.0,
      application_fee: 10.0,
      area_rate: 10.0,
      daily_late_fee_addition: 10.0,
      grace_period: 10,
      late_fee_amount: 10.0,
      late_fee_threshold: 10.0,
      late_fee_type: "$",
      mtm_multiplier: 1.0,
      notice_period: 2
    }
    |> Map.merge(extra)
  end

  test "get_aggregate/1" do
    builder =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.add_admin_with_access()

    admin = PropBuilder.get_requirement(builder, :admin)
    property = PropBuilder.get_requirement(builder, :property)

    # When
    admin_aggregate = AdminRepo.get_aggregate(admin.id)

    # Admin --< Permission
    assert admin_aggregate.permissions
    [permission | _] = admin_aggregate.permissions
    # Admin --< Permission >--- Region ---< Scoping
    assert permission.region.scopings
    [scoping | _] = permission.region.scopings
    # Admin --< Permission >--- Region ---< Scoping  >-- Property
    assert scoping.property
    assert scoping.property.id == property.id
  end

  test "get_aggregate/1 setting active is false" do
    builderA =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.add_admin_with_access()

    admin = PropBuilder.get_requirement(builderA, :admin)

    builderA
    |> PropBuilder.get_requirement(:property)
    |> PropertyRepo.update_property_settings(
      ClientSchema.new("dasmen", default_setting(%{active: false}))
    )

    builderB =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.add_region()
      |> PropBuilder.add_scoping()
      |> PropBuilder.put_requirement(:admin, admin)
      |> PropBuilder.add_permission()

    builderB
    |> PropBuilder.get_requirement(:property)
    |> PropertyRepo.update_property_settings(
      ClientSchema.new("dasmen", default_setting(%{active: true}))
    )

    # When
    admin_aggregate = AdminRepo.get_aggregate(admin.id)

    properties_on_aggregate = Admin.properties(admin_aggregate)
    assert 1 == length(properties_on_aggregate)
  end
end
