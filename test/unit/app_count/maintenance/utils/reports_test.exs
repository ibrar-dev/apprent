defmodule AppCount.Maintenance.Utils.ReportsTest do
  use AppCount.DataCase
  alias AppCount.Maintenance.Utils.Reports
  alias AppCount.Core.ClientSchema

  @moduletag :reports

  #  @start_date %Date{year: 2018, month: 6, day: 1}
  #  @end_date %Date{year: 2019, month: 5, day: 31}

  setup do
    property = insert(:property)
    admin = admin_with_access([property.id])
    {:ok, %{property: property, admin: admin}}
  end

  test "property_stats_query_by_admin_dates", %{property: property, admin: admin} do
    category = insert(:category)
    completed = Timex.shift(DateTime.utc_now(), days: 5)
    order = insert(:order, property: property, category: category)
    assignment = insert(:assignment, status: "completed", order: order, completed_at: completed)
    end_date = Timex.today() |> Timex.shift(days: 1) |> Timex.to_naive_datetime()
    start_date = Timex.shift(end_date, days: -10) |> Timex.to_naive_datetime()

    rep =
      Reports.property_stats_query_by_admin_dates(
        ClientSchema.new("dasmen", admin),
        start_date,
        end_date
      )

    assert length(rep) == 1

    expected_completion_time =
      Timex.diff(assignment.completed_at, assignment.inserted_at, :seconds)

    assert_in_delta List.first(rep).average_completion_time, expected_completion_time, 1
  end
end
