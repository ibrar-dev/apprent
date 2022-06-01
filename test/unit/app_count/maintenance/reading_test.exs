defmodule AppCount.Maintenance.ReadingTest do
  use AppCount.DataCase
  alias AppCount.Maintenance.Reading

  describe "json" do
    setup do
      json =
        ~S[{"name":"work_order_turnaround","title":"Average Open Ticket Duration","display":"duration","value":3,"link_path":"orders?selected_properties=99"}]

      reading =
        Reading.work_order_turnaround(3)
        |> Reading.put_property(99)

      ~M[reading, json]
    end

    test "encode", ~M[reading, json] do
      result = Jason.encode!(reading)
      assert result == json
    end
  end

  describe "valid?" do
    test "false, nil" do
      reading = %Reading{}
      assert false == Reading.valid_link_path?(reading)
    end

    test "false, =" do
      reading = %Reading{
        link_path: "maintenance_reports?selected_properties="
      }

      assert false == Reading.valid_link_path?(reading)
    end

    test "true (has a property_id)" do
      reading = %Reading{
        link_path: "maintenance_reports?selected_properties=1"
      }

      assert true == Reading.valid_link_path?(reading)
    end
  end

  describe "put_property" do
    setup do
      property_id = 99
      reading = %Reading{}
      ~M[property_id, reading]
    end

    test "adds property_id", ~M[property_id, reading] do
      reading = Reading.put_property(reading, property_id)
      assert reading.link_path == "#{property_id}"
    end

    test "adds property_id after =", ~M[property_id, reading] do
      reading = %{reading | link_path: "maintenance_reports?selected_properties="}
      reading = Reading.put_property(reading, property_id)
      assert reading.link_path == "maintenance_reports?selected_properties=#{property_id}"
    end

    test "no not change link_path", ~M[property_id, reading] do
      reading = %{reading | link_path: "maintenance_reports?selected_properties=#{property_id}"}
      reading = Reading.put_property(reading, property_id)
      assert reading.link_path == "maintenance_reports?selected_properties=#{property_id}"
    end
  end

  describe "constructor" do
    setup do
      expected = %AppCount.Maintenance.Reading{
        display: "number",
        link_path: "maintenance_reports?selected_properties=",
        measure: {0, :count},
        name: :work_order_callbacks,
        title: "Callbacks submitted",
        value: 0
      }

      ~M[expected]
    end

    test "work_order_callbacks", ~M[expected] do
      reading = Reading.work_order_callbacks(0)
      assert reading == expected
    end

    test "build", ~M[expected] do
      reading = Reading.build(:work_order_callbacks, 0)
      assert reading == expected
    end
  end
end
