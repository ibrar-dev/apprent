defmodule AppCount.Admins.AdminTest do
  @moduledoc """

  Admin  - Permission - Region - Scoping - PropertyA
         - Permission
         - Permission - Region - Scoping - PropertyB
                               - Scoping - PropertyC
                               - Scoping - PropertyD
                               - Scoping - PropertyE

  """
  use AppCount.DataCase
  alias AppCount.Admins.Admin
  alias AppCount.Admins.AdminRepo

  describe "put_role" do
    test "Super Admin" do
      super_admin_name = "Super Admin"
      admin_name = "Admin"
      # When
      admin =
        %Admin{}
        |> Admin.put_role(super_admin_name)
        |> Admin.put_role(admin_name)

      assert Admin.has_role?(admin, super_admin_name)
      assert Admin.has_role?(admin, admin_name)
    end
  end

  describe "has_role?" do
    test "Super Admin" do
      super_admin = "Super Admin"

      admin = Admin.put_role(%Admin{}, super_admin)
      assert Admin.has_role?(admin, super_admin)
    end

    test "not Super Admin" do
      super_admin = "Super Admin"
      admin = %Admin{}
      refute Admin.has_role?(admin, super_admin)
    end
  end

  describe "is_super_admin?" do
    test "Super Admin" do
      admin = Admin.put_super_admin(%Admin{})
      assert Admin.is_super_admin?(admin)
    end

    test "not Super Admin" do
      admin = %Admin{}
      refute Admin.is_super_admin?(admin)
    end
  end

  describe "is_admin?" do
    test "Admin" do
      admin = Admin.put_admin(%Admin{})
      assert Admin.is_admin?(admin)
    end

    test "not Admin" do
      admin = %Admin{}
      refute Admin.is_admin?(admin)
    end
  end

  describe "is_regional?" do
    test "Regional" do
      admin = Admin.put_regional(%Admin{})
      assert Admin.is_regional?(admin)
    end

    test "not Regional" do
      admin = %Admin{}
      refute Admin.is_regional?(admin)
    end
  end

  test "add_admin_with_access creates permissions" do
    builder =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.add_admin_with_access()

    admin = PropBuilder.get_requirement(builder, :admin)
    admin = AdminRepo.get_aggregate(admin.id)
    property = PropBuilder.get_requirement(builder, :property)

    assert Admin.permitted?(admin, property) == true
  end

  test "add_admin has no permissions" do
    builder =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.add_admin()

    admin = PropBuilder.get_requirement(builder, :admin)
    admin = AdminRepo.get_aggregate(admin.id)
    property = PropBuilder.get_requirement(builder, :property)

    assert Admin.permitted?(admin, property) == false
  end

  test "add_admin 'Super Admin' has ALL permissions" do
    builder =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.add_super_admin()

    admin = PropBuilder.get_requirement(builder, :admin)
    admin = AdminRepo.get_aggregate(admin.id)
    property = PropBuilder.get_requirement(builder, :property)

    # When
    assert Admin.permitted?(admin, property) == true
  end

  test "add_admin_with_access with multiple permissions, all return true" do
    #  Admin  - Permission - Region - Scoping - PropertyA !!
    #      - Permission
    #      - Permission - Region - Scoping - PropertyB *(tested)

    builderA =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.add_admin_with_access()

    admin = PropBuilder.get_requirement(builderA, :admin)
    propertyA = PropBuilder.get_requirement(builderA, :property)

    propertyB =
      PropBuilder.new(:create)
      # create PropertyB
      |> PropBuilder.add_property()
      |> PropBuilder.add_region()
      |> PropBuilder.add_scoping()
      |> PropBuilder.put_requirement(:admin, admin)
      |> PropBuilder.add_permission()
      |> PropBuilder.get_requirement(:property)

    admin = AdminRepo.get_aggregate(admin.id)

    # When
    assert Admin.permitted?(admin, propertyA) == true
    assert Admin.permitted?(admin, propertyB) == true
  end

  test "properties" do
    builderA =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.add_property_setting()
      |> PropBuilder.add_admin_with_access()

    admin = PropBuilder.get_requirement(builderA, :admin)

    PropBuilder.new(:create)
    # create PropertyB
    |> PropBuilder.add_property()
    |> PropBuilder.add_property_setting()
    |> PropBuilder.add_region()
    |> PropBuilder.add_scoping()
    |> PropBuilder.put_requirement(:admin, admin)
    |> PropBuilder.add_permission()
    |> PropBuilder.get_requirement(:property)

    admin_aggregate = AppCount.Admins.AdminRepo.get_aggregate(admin.id)

    # When
    properties = Admin.properties(admin_aggregate)

    assert length(properties) == 2
  end

  def unpermitted_property do
    PropBuilder.new(:create)
    |> PropBuilder.add_property()
    |> PropBuilder.get_requirement(:property)
  end
end
