defmodule AppCount.Support.PropertyBuilderTest do
  use AppCount.DataCase
  alias AppCount.Properties.Property
  alias AppCount.Admins.AdminRepo
  alias AppCount.Properties.Scoping
  alias AppCount.Admins.Permission
  alias AppCount.Admins.Region
  alias AppCount.Ledgers.PaymentRepo
  @hour_in_seconds 60 * 60

  describe "extra attrs" do
    test "account with default attrs" do
      property =
        PropBuilder.new(:create)
        |> PropBuilder.add_property()
        |> PropBuilder.get_requirement(:property)

      assert property.name =~ ~r[Test Property-]
    end

    test "account with extra attrs" do
      property =
        PropBuilder.new(:create)
        |> PropBuilder.add_property(name: "TreeCity")
        |> PropBuilder.get_requirement(:property)

      assert property.name == "TreeCity"
    end
  end

  describe "auto associate Feature" do
    test "create" do
      feature =
        PropBuilder.new(:create)
        |> PropBuilder.add_property()
        |> PropBuilder.add_feature()
        |> PropBuilder.get_requirement(:feature)

      assert feature.property_id
      refute Ecto.assoc_loaded?(feature.property)
      Ecto
    end
  end

  describe "builder create" do
    test "get/2 property" do
      property =
        PropBuilder.new(:create)
        |> PropBuilder.add_property()
        |> PropBuilder.get_requirement(:property)

      assert %Property{} = property
    end

    test "get/2 invalid_name not found" do
      result =
        PropBuilder.new(:create)
        |> PropBuilder.get_requirement(:invalid_name)

      assert result == "invalid_name Not Found"
    end

    test "add_property inserts into DB" do
      original_count = Repo.count(Property)

      _builder =
        PropBuilder.new(:create)
        |> PropBuilder.add_property()

      after_count = Repo.count(Property)
      assert after_count == original_count + 1
    end

    test "add_admin inserts into DB" do
      original_count = AdminRepo.count()

      _builder =
        PropBuilder.new(:create)
        |> PropBuilder.add_property()
        |> PropBuilder.add_admin()

      after_count = AdminRepo.count()

      assert after_count == original_count + 1
    end

    test "add_admin_with_access inserts lots into DB" do
      original_count = AdminRepo.count()
      original_entity_count = Repo.count(Region)
      original_scoping_count = Repo.count(Scoping)
      original_permission_count = Repo.count(Permission)

      _builder =
        PropBuilder.new(:create)
        |> PropBuilder.add_property()
        |> PropBuilder.add_admin_with_access()

      after_count = AdminRepo.count()
      after_entity_count = Repo.count(Region)
      after_scoping_count = Repo.count(Scoping)
      after_permission_count = Repo.count(Permission)

      assert after_count == original_count + 1
      assert after_entity_count == original_entity_count + 1
      assert after_scoping_count == original_scoping_count + 1
      assert after_permission_count == original_permission_count + 1
    end

    test "new(:create) add_ABC inserts into DB" do
      original_property_count = Repo.count(Property)

      _builder =
        PropBuilder.new(:create)
        |> PropBuilder.add_property()

      assert Repo.count(Property) == original_property_count + 1
    end
  end

  describe "property with" do
    setup do
      builder =
        PropBuilder.new(:create)
        |> PropBuilder.add_property()
        |> PropBuilder.add_tech()
        |> PropBuilder.add_unit()
        |> PropBuilder.add_unit_category()

      now = naive_now()

      times = %{
        query_begin: NaiveDateTime.add(now, -24 * @hour_in_seconds, :second),
        task01_begin: NaiveDateTime.add(now, -14 * @hour_in_seconds, :second),
        task02_begin: NaiveDateTime.add(now, -4 * @hour_in_seconds, :second)
      }

      property = builder.req.property

      admin = Factory.admin_with_access([property.id])

      ~M[builder, times, admin]
    end

    test "PropBuilder get Assignment and Work Order",
         ~M[builder, times, admin] do
      client = AppCount.Public.get_client_by_schema("dasmen")

      # When
      builder =
        PropBuilder.create_unit_work_order(
          builder,
          times.task01_begin,
          admin,
          client.client_schema
        )

      # Then
      found_assignment = PropBuilder.get_requirement(builder, :assignment)
      assert found_assignment.__struct__ == AppCount.Maintenance.Assignment

      # Then
      found_work_order = PropBuilder.get_requirement(builder, :work_order)
      assert found_work_order.__struct__ == AppCount.Maintenance.Order
    end
  end

  test "add_payment" do
    original_count = PaymentRepo.count()

    builder =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()

    # When
    builder = PropBuilder.add_payment(builder, last_4: "1234")

    # Then
    payment = PropBuilder.get_requirement(builder, :payment)

    assert payment.status == "cleared"
    assert payment.last_4 == "1234"

    actual_count = PaymentRepo.count()
    assert actual_count == original_count + 1
  end
end
