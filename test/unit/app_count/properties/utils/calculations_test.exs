defmodule AppCount.Properties.CalculationsTest do
  use AppCount.DataCase
  import AppCount.LeasingHelper
  alias AppCount.Properties
  @moduletag :properties_calculations

  setup do
    {:ok, property: insert(:property)}
  end

  @tag :slow
  test "calculate_trend", %{property: property} do
    yesterday =
      AppCount.current_date()
      |> Timex.shift(days: -1)

    start_date = AppCount.current_date()
    end_date = Timex.shift(start_date, years: 1)
    unit = insert(:unit, property: property)
    assert Properties.calculate_trend([property.id], 100) == 0
    insert_lease(%{unit: unit, start_date: start_date, end_date: end_date})
    assert Properties.calculate_trend([property.id], 100) == 100

    insert_lease(%{
      charges: [Rent: 500],
      property: property,
      notice_date: yesterday,
      expected_move_out: Timex.shift(yesterday, days: 60)
    })

    assert Properties.calculate_trend([property.id], nil) == 50.0
    result = Properties.calculate_trend_detailed([property.id], 100)
    assert result.notice_units == 1
    assert result.occupied_units == 2
    assert result.model_units == 0
    result = Properties.calculate_trend_multiple([property.id])
    assert result.thirty == 100
    assert result.sixty == 50.0
  end
end
