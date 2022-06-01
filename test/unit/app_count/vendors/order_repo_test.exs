defmodule AppCount.Vendors.OrderRepoTest do
  use AppCount.VendorsCase
  alias AppCount.Support.PropertyBuilder, as: PropBuilder
  alias AppCount.Core.ClientSchema

  describe "order in DB" do
    setup do
      order = insert_order()
      ~M[order]
    end

    test "get order from id", ~M[order] do
      assert OrderRepo.get(order.id)
    end

    test "get_aggregate()", ~M[order] do
      full_order = OrderRepo.get_aggregate(order.id)
      assert Ecto.assoc_loaded?(full_order.category)
    end
  end

  describe "currently open/1" do
    setup do
      builder =
        PropBuilder.new(:create)
        |> PropBuilder.add_property()
        |> PropBuilder.add_unit()
        |> PropBuilder.add_vendor()
        |> PropBuilder.add_vendor_category()
        |> PropBuilder.add_vendor_work_order()

      second_builder =
        PropBuilder.new(:create)
        |> PropBuilder.add_property()
        |> PropBuilder.add_unit()
        |> PropBuilder.add_vendor()
        |> PropBuilder.add_vendor_category()
        |> PropBuilder.add_vendor_work_order()

      property =
        builder
        |> PropBuilder.get_requirement(:property)

      second_property =
        second_builder
        |> PropBuilder.get_requirement(:property)

      vendor_work_order =
        builder
        |> PropBuilder.get_requirement(:vendor_work_order)

      second_vendor_work_order =
        second_builder
        |> PropBuilder.get_requirement(:vendor_work_order)

      ~M[property, vendor_work_order, second_property, second_vendor_work_order]
    end

    test "gets vendor open orders", ~M[property, vendor_work_order] do
      property_id = property.id

      result = OrderRepo.currently_open(ClientSchema.new("dasmen", property_id))

      assert result == [vendor_work_order]
    end

    test "gets currently open orders when the property ID is in list",
         ~M[property, vendor_work_order] do
      property_id_in_list = [property.id]

      result = OrderRepo.currently_open(ClientSchema.new("dasmen", property_id_in_list))

      assert result == [vendor_work_order]
    end

    test "gets currently open orders with more than 1 property",
         ~M[property, second_property, vendor_work_order, second_vendor_work_order] do
      property_ids_in_list = [property.id, second_property.id]

      results = OrderRepo.currently_open(ClientSchema.new("dasmen", property_ids_in_list))

      assert Enum.member?(results, vendor_work_order)
      assert Enum.member?(results, second_vendor_work_order)
    end
  end
end
