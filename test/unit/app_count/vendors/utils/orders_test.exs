defmodule AppCount.Vendors.Utils.OrdersTest do
  use AppCount.VendorsCase
  alias AppCount.Vendors.Utils.Orders
  alias AppCount.Support.PropertyBuilder, as: PropBuilder
  alias AppCount.Core.ClientSchema

  @client_schema "dasmen"

  setup do
    [_builder, vendor_work_order] =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.add_unit()
      |> PropBuilder.add_vendor()
      |> PropBuilder.add_vendor_category()
      |> PropBuilder.add_vendor_work_order()
      |> PropBuilder.get([:vendor_work_order])

    ~M[vendor_work_order]
  end

  describe "save_notes/2" do
    test "matches an ok tuple", ~M[vendor_work_order] do
      ok_tuple = {:ok, vendor_work_order}

      # We give the function a bogus work id since we can't test the actual deletion due to it being in Tasker
      work_order_id = AppCount.Core.ClientSchema.new("dasmen", 123)

      # When
      result = Orders.save_notes(ok_tuple, work_order_id)

      # Then
      assert result == ok_tuple
    end

    test "matches an error tuple", ~M[vendor_work_order] do
      error_tuple = {:error, vendor_work_order}
      work_order_id = 123

      # When
      result = Orders.save_notes(error_tuple, work_order_id)

      # Then
      assert result == error_tuple
    end
  end

  describe "remove_maintenance_orders/2" do
    test "matches on ok tuple", ~M[vendor_work_order] do
      ok_tuple = {:ok, vendor_work_order}
      work_order_id = 123

      # When
      result =
        Orders.remove_maintenance_order(ok_tuple, ClientSchema.new(@client_schema, work_order_id))

      # Then
      assert result == ok_tuple
    end

    test "matches on error tuple", ~M[vendor_work_order] do
      error_tuple = {:error, vendor_work_order}
      work_order_id = 123

      # When
      result = Orders.remove_maintenance_order(error_tuple, work_order_id)

      # Then
      assert result == error_tuple
    end
  end
end
