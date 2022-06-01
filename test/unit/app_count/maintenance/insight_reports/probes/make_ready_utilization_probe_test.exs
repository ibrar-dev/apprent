defmodule AppCount.Maintenance.InsightReports.MakeReadyUtilizationProbeTest do
  use AppCount.ProbeCase
  alias AppCount.Maintenance.InsightReports.MakeReadyUtilizationProbe

  describe "calculate_percentage/1" do
    setup do
      date = Timex.now()

      builder =
        PropBuilder.new(:create)
        |> PropBuilder.add_property()

      ~M[date, builder]
    end

    test "returns 0 for a property with no vacant units", ~M[builder] do
      property =
        builder
        |> PropBuilder.get_requirement(:property)

      unit_status = []

      result = MakeReadyUtilizationProbe.calculate_percentage(property, unit_status)

      assert result == 0
    end

    test "returns 100.0 for a property with 1 unit on the make ready board", ~M[builder] do
      card_attrs = [
        completion: nil
      ]

      property =
        builder
        |> PropBuilder.add_unit()
        |> PropBuilder.add_card(card_attrs)
        |> PropBuilder.get_requirement(:property)

      unit_status = [
        %{status: "Vacant Unrented Not Ready"}
      ]

      result = MakeReadyUtilizationProbe.calculate_percentage(property, unit_status)

      assert result == 100.0
    end

    test "returns 50.0 for a property with 1 unit on the make ready board with a total of 2 units in the repo",
         ~M[builder] do
      card_attrs = [
        completion: nil
      ]

      property =
        builder
        |> PropBuilder.add_unit()
        |> PropBuilder.add_card(card_attrs)
        |> PropBuilder.get_requirement(:property)

      unit_status = [
        %{status: "Vacant Unrented Not Ready"},
        %{status: "Vacant Unrented Not Ready"},
        %{status: "Occupied"},
        %{status: "RENO"}
      ]

      result = MakeReadyUtilizationProbe.calculate_percentage(property, unit_status)

      assert result == 50.0
    end

    test "counts both ready and not-ready vacant units", ~M[date,builder] do
      not_ready_card_attrs = [
        completion: nil
      ]

      ready_card_attrs = [
        completion: %{
          "date" => DateTime.to_iso8601(date),
          "name" => "blah"
        }
      ]

      property =
        builder
        |> PropBuilder.add_unit()
        |> PropBuilder.add_card(not_ready_card_attrs)
        |> PropBuilder.add_unit()
        |> PropBuilder.add_card(ready_card_attrs)
        |> PropBuilder.get_requirement(:property)

      unit_status = [
        %{status: "Vacant Unrented Not Ready"},
        %{status: "Vacant Unrented Ready"},
        %{status: "Occupied"},
        %{status: "RENO"}
      ]

      result = MakeReadyUtilizationProbe.calculate_percentage(property, unit_status)

      assert result == 100.0
    end

    test "catches when there's more units on MR board than there are in the repo", ~M[builder] do
      card_attrs = [
        completion: nil
      ]

      property =
        builder
        |> PropBuilder.add_unit()
        |> PropBuilder.add_card(card_attrs)
        |> PropBuilder.add_unit()
        |> PropBuilder.add_card(card_attrs)
        |> PropBuilder.get_requirement(:property)

      unit_status = [
        %{status: "Vacant Unrented Not Ready"}
      ]

      result = MakeReadyUtilizationProbe.calculate_percentage(property, unit_status)

      assert result == 200.0
    end
  end

  describe "comments/1" do
    test "returns an empty list when percentage is nil" do
      percentage = nil

      result = MakeReadyUtilizationProbe.comments(percentage)

      expected = []

      assert result == expected
    end

    test "returns an empty list when percentage is 0" do
      percentage = 0

      result = MakeReadyUtilizationProbe.comments(percentage)

      expected = []

      assert result == expected
    end

    test "returns positive comment when percentage is greater than 90" do
      percentage = 95.4

      result = MakeReadyUtilizationProbe.comments(percentage)

      expected = ["Great job utilizing the Make Ready board!"]

      assert result == expected
    end

    test "returns negative comment when percentage is less than 75" do
      percentage = 47.8

      result = MakeReadyUtilizationProbe.comments(percentage)

      expected = ["The Make Ready is missing some vacant units. Please work to include them."]

      assert result == expected
    end

    test "returns an empty list when percentage is between 75 and 90" do
      percentage = 80.4

      result = MakeReadyUtilizationProbe.comments(percentage)

      expected = []

      assert result == expected
    end
  end
end
