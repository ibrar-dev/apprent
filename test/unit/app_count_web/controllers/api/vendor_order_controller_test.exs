defmodule AppCountWeb.API.VendorOrderControllerTest do
  use AppCountWeb.ConnCase
  use AppCount.Case
  alias AppCount.Core.ClientSchema
  alias AppCount.Support.PropertyBuilder, as: PropBuilder

  defmodule VendorOrderParrot do
    use TestParrot

    parrot(:vendor_order_boundary, :create_orders, [{:ok, %{order: "this is our order"}}])
  end

  setup do
    [_builder, admin] =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.add_admin()
      |> PropBuilder.get([:admin])

    ~M[admin]
  end

  def create_order_map() do
    order_params = %{
      "id" => 1123,
      "note" => "foo bar"
    }

    _data_from_front_end = %{
      "orders" => [order_params]
    }
  end

  @tag subdomain: "administration"
  test "'create' successfully posts and constructs an order", ~M[admin, conn] do
    data_from_front_end = create_order_map()

    expected_orders = %{
      orders: [
        %{
          "admin_id" => admin.id,
          "id" => 1123,
          "note" => "foo bar",
          "order_id" => 1123
        }
      ]
    }

    expected_response = ClientSchema.new("dasmen", expected_orders)

    conn =
      assign(conn, :vendor_order_boundary, VendorOrderParrot)
      |> admin_request(admin)

    # When
    conn = post(conn, Routes.api_vendor_order_path(conn, :create), data_from_front_end)

    # Then
    assert json_response(conn, 200) == %{}
    assert_receive {:create_orders, ^expected_response}
  end

  @tag subdomain: "administration"
  test "'create' fails and returns a 422", ~M[admin, conn] do
    VendorOrderParrot.say_create_orders([{:error, "error message"}])

    data_from_front_end = create_order_map()

    expected_orders = %{
      orders: [
        %{
          "admin_id" => admin.id,
          "id" => 1123,
          "note" => "foo bar",
          "order_id" => 1123
        }
      ]
    }

    expected_response = ClientSchema.new("dasmen", expected_orders)

    conn =
      assign(conn, :vendor_order_boundary, VendorOrderParrot)
      |> admin_request(admin)

    # When
    conn = post(conn, Routes.api_vendor_order_path(conn, :create), data_from_front_end)

    # Then
    assert json_response(conn, 422) == "Not all orders were successfully outsourced"
    assert_receive {:create_orders, ^expected_response}
  end
end
