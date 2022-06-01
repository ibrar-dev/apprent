defmodule AppCount.Maintenance.Utils.Queries.OrdersTest do
  use AppCount.DataCase
  alias AppCount.Maintenance.Utils.Queries.Orders
  alias AppCount.Core.ClientSchema

  test "get_dates" do
    end_of_day = Timex.today() |> Timex.to_naive_datetime() |> Timex.end_of_day()
    assert Orders.get_dates(nil) == [~N[2020-06-01 00:00:00], end_of_day]
    assert Orders.get_dates("") == [~N[2020-06-01 00:00:00], end_of_day]

    assert Orders.get_dates("2021-01-01,2020-02-02") == [
             ~N[2021-01-01 00:00:00],
             ~N[2020-02-02 23:59:59]
           ]
  end

  describe "list_orders/3" do
    setup do
      builder =
        PropBuilder.new(:create)
        |> PropBuilder.add_property()
        |> PropBuilder.add_property_setting()
        |> PropBuilder.add_unit()
        |> PropBuilder.add_parent_category()
        |> PropBuilder.add_category()
        |> PropBuilder.add_work_order_on_unit()

      [_builder, order, property, unit] =
        PropBuilder.get(builder, [:work_order, :property, :unit])

      ~M[order, property, unit]
    end

    test "zero", %{property: property} do
      admin = %{id: 999, property_ids: [property.id]}
      dates = ""
      provided_property_ids = []
      client = AppCount.Public.get_client_by_schema("dasmen")

      result =
        Orders.list_orders(
          admin,
          dates,
          ClientSchema.new(client.client_schema, provided_property_ids)
        )

      assert result == %{assigned: [], cancelled: [], completed: [], unassigned: []}
    end

    test "one unassigneds", ~M[property] do
      dates = ""
      provided_property_ids = [property.id]
      client = AppCount.Public.get_client_by_schema("dasmen")
      # When
      %{assigned: [], cancelled: [], completed: [], unassigned: [one_order]} =
        Orders.list_orders(
          %{property_ids: [property.id]},
          dates,
          ClientSchema.new(client.client_schema, provided_property_ids)
        )

      one_order =
        Map.drop(
          one_order,
          [
            :inserted_at,
            :id,
            :unit,
            :property_id,
            :property,
            :parent_category,
            :parent_category_id,
            :category_id,
            :category
          ]
        )

      random_fields_acting_like_an_order = %{
        assignments: nil,
        cancellation: nil,
        card: nil,
        # category: "533813 Bedrooms",
        # category_id: 1309,
        completed_at: nil,
        created_by: nil,
        entry_allowed: false,
        has_pet: false,
        # id: 855,
        no_access: [],
        notes_count: nil,
        # parent_category: "533812 Bedrooms",
        # parent_category_id: 1308,
        priority: 1,
        # property: "Test Property-#{}",
        # property_id: property.id,
        status: "unassigned",
        tenant: nil,
        ticket: "UNKNOWN",
        type: "Maintenance"
        # unit: %{
        #   area: 0,
        #   id: unit.id,
        #   number: "533809"
        # }
      }

      assert one_order == random_fields_acting_like_an_order
    end
  end
end
